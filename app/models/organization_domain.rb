# frozen_string_literal: true

class OrganizationDomain < ApplicationRecord
  TXT_NAME_PREFIX = "_rubygems-challenge."
  TXT_VALUE_PREFIX = "rubygems-verification="
  TOKEN_ATTEMPTS = 3

  belongs_to :organization
  has_many :checks, -> { order(checked_at: :desc, id: :desc) },
    class_name: "OrganizationDomainCheck", inverse_of: :organization_domain, dependent: :destroy

  has_many :audits, as: :auditable, dependent: :nullify

  attr_readonly :domain, :token

  scope :not_deleted, -> { where(deleted_at: nil) }
  scope :verified, -> { not_deleted.where.not(verified_at: nil) }
  scope :pending, -> { not_deleted.where(verified_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }

  before_validation :normalize_domain, on: :create
  before_validation :generate_token, on: :create
  validate :domain_name_is_valid, on: :create
  validates :domain, uniqueness: { scope: :organization_id, conditions: -> { not_deleted } }, on: :create

  def verified?
    verified_at.present?
  end

  def remove!
    update!(deleted_at: Time.current, verified_at: nil)
  end

  # Runs a synchronous DNS check and returns the recorded OrganizationDomainCheck.
  # Raises (without querying DNS) for a removed or invalid domain.
  def verify!(resolver: nil)
    DnsCheck.call(self, resolver:)
  end

  def txt_record_name
    "#{TXT_NAME_PREFIX}#{domain}"
  end

  def txt_record_value
    "#{TXT_VALUE_PREFIX}#{token}"
  end

  private

  # The only changes made to the owner's input; anything else invalid is an error.
  def normalize_domain
    self.domain = domain.strip.downcase if domain.is_a?(String)
  end

  def generate_token
    self.token = SecureRandom.urlsafe_base64(32)
  end

  def domain_name_is_valid
    Name.errors_for(domain).each do |error|
      errors.add(:domain, error.key, **message_options(error))
    end
  end

  def message_options(error)
    characters = error.characters.map { |char| "`#{char}`" }.to_sentence(two_words_connector: ", ", last_word_connector: ", ")
    hint = error.hint ? " #{I18n.t(error.hint, scope: 'activerecord.errors.models.organization_domain.hints')}" : ""
    { characters:, hint: }
  end

  # The unique index on token guarantees no duplicate; on the near-impossible
  # collision, regenerate and retry the insert rather than pre-checking (racy).
  def _create_record(*)
    attempts = 0
    begin
      self.class.transaction(requires_new: true) { super }
    rescue ActiveRecord::RecordNotUnique => e
      raise unless e.message.include?("index_organization_domains_on_token")
      raise if (attempts += 1) >= TOKEN_ATTEMPTS

      generate_token
      retry
    end
  end
end
