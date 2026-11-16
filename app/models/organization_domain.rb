# frozen_string_literal: true

class OrganizationDomain < ApplicationRecord
  class VerificationError < StandardError; end
  class InvalidDomain < VerificationError; end
  class DeletedDomain < VerificationError; end

  TXT_NAME_PREFIX = "_rubygems-challenge."
  TXT_VALUE_PREFIX = "rubygems-verification="
  TOKEN_ATTEMPTS = 3
  STALE_CHECK_AFTER = 10.minutes
  LIMIT = 5

  belongs_to :organization
  has_many :checks, -> { order(checked_at: :desc, id: :desc) },
    class_name: "OrganizationDomainCheck", inverse_of: :organization_domain, dependent: :destroy

  has_many :audits, as: :auditable, dependent: :nullify

  attr_readonly :domain, :token

  scope :verified, -> { where.not(verified_at: nil) }
  scope :pending, -> { where(verified_at: nil) }

  scope :checking, -> { where(check_queued_at: STALE_CHECK_AFTER.ago..) }
  scope :not_checking, -> { where(check_queued_at: nil).or(where(check_queued_at: ...STALE_CHECK_AFTER.ago)) }

  before_validation :normalize_domain, on: :create
  before_validation :generate_token, on: :create
  after_create :record_added_event
  validate :domain_name_is_valid, on: :create
  validates :domain, uniqueness: { scope: :organization_id }, on: :create
  validate :organization_under_limit, on: :create

  def self.add(organization:, domain:)
    record = new(organization:, domain:)
    attempts = 0
    begin
      transaction(requires_new: true) { record.save }
    rescue ActiveRecord::RecordNotUnique => e
      if e.message.include?("index_organization_domains_on_organization_id_and_domain")
        record.errors.add(:domain, :taken)
      elsif e.message.include?("index_organization_domains_on_token") && (attempts += 1) < TOKEN_ATTEMPTS
        retry
      else
        raise
      end
    end
    record
  end

  def checking?
    check_queued_at.present? && check_queued_at > STALE_CHECK_AFTER.ago
  end

  def verified?
    verified_at.present?
  end

  def destroy_with_audit!(actor:)
    transaction do
      lock!
      organization.record_event!(Events::OrganizationEvent::DOMAIN_DELETED, domain:, txt_record_value:, actor_gid: actor.to_gid)
      destroy!
    end
  end

  def verify!(resolver: nil)
    ensure_verifiable!
    result = DnsCheck.call(name: txt_record_name, expected_value: txt_record_value, resolver:)
    record_verification(result)
  end

  def record_check!(outcome:, message:)
    success = outcome == "matched"
    result = success ? "success" : "failure"
    checked_at = Time.current
    self.class.transaction(requires_new: true) do
      lock!
      check = OrganizationDomainCheck.create!(organization_domain: self, checked_at:, result:, outcome:, message:)
      update_columns(verified_at: (checked_at if success), last_checked_at: checked_at,
        last_check_result: result, check_queued_at: nil, updated_at: checked_at)
      check
    end
  end

  def txt_record_name
    "#{TXT_NAME_PREFIX}#{domain}"
  end

  def txt_record_value
    "#{TXT_VALUE_PREFIX}#{token}"
  end

  private

  def ensure_verifiable!
    raise InvalidDomain, "domain has unsaved changes" if new_record? || changed?
    raise DeletedDomain, "domain has been deleted" if destroyed? || !self.class.exists?(id)
    raise InvalidDomain, "stored domain is invalid" unless Name.valid?(domain)
  end

  def record_verification(result)
    record_check!(outcome: result.outcome, message: result.message)
  rescue ActiveRecord::RecordNotUnique => e
    raise unless e.message.include?("index_organization_domains_on_domain_verified")

    record_check!(outcome: "other_error", message: "Another organization has already verified this domain.")
  rescue ActiveRecord::RecordNotFound
    raise DeletedDomain, "domain was deleted during the check"
  end

  def normalize_domain
    self.domain = domain.strip.downcase if domain.is_a?(String)
  end

  def record_added_event
    organization.record_event!(Events::OrganizationEvent::DOMAIN_ADDED, domain:, txt_record_value:, actor_gid: Current.user&.to_gid)
  end

  def generate_token
    self.token = SecureRandom.urlsafe_base64(32)
  end

  def organization_under_limit
    return if organization.nil? || self.class.where(organization_id:).count < LIMIT

    errors.add(:base, :limit_reached, count: LIMIT)
  end

  def domain_name_is_valid
    rules = Name.errors_for(domain)
    errors.add(:domain, :invalid_format, rules:) if rules.any?
  end
end
