# frozen_string_literal: true

class OrganizationDomain < ApplicationRecord
  # Raised by verify! before any DNS request when the domain can't be checked.
  class VerificationError < StandardError; end
  class InvalidDomain < VerificationError; end
  class DeletedDomain < VerificationError; end

  TXT_NAME_PREFIX = "_rubygems-challenge."
  TXT_VALUE_PREFIX = "rubygems-verification="
  TOKEN_ATTEMPTS = 3
  # A check queued longer ago than this is treated as lost (so a row never stays "Checking" forever).
  STALE_CHECK_AFTER = 10.minutes

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

  # Adds a domain for an organization and returns the record: persisted, or with
  # errors (invalid, or taken by a concurrent add). The unique index on token
  # guarantees no duplicate token; on the near-impossible collision the save is
  # retried (before_validation generates a fresh token) rather than pre-checked
  # (racy). The added event is recorded by the record's own after_create, so it
  # shares the insert's transaction and a failed or retried attempt leaves none.
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

  # Deletes the domain and its checks. The event is recorded in the same
  # transaction, so a recorded event always matches a real deletion.
  def destroy_with_audit!(actor:)
    transaction do
      # Raises RecordNotFound if the row is already gone (so no event is recorded
      # for a no-op) and serialises with record_check!, which locks the same row.
      lock!
      organization.record_event!(Events::OrganizationEvent::DOMAIN_DELETED, domain:, txt_record_value:, actor_gid: actor.to_gid)
      destroy!
    end
  end

  # Runs a DNS check in the calling thread (the background job's work) and returns the recorded OrganizationDomainCheck.
  # Raises early (without querying DNS) if the domain can't be checked: unsaved or
  # changed, deleted, or with an invalid stored name. DnsCheck only makes the request.
  def verify!(resolver: nil)
    ensure_verifiable!
    result = DnsCheck.call(name: txt_record_name, expected_value: txt_record_value, resolver:)
    record_verification(result)
  end

  # The one place a check result is recorded. Locks and re-reads the row (raises
  # ActiveRecord::RecordNotFound if it was deleted), then in one transaction
  # creates the check, updates the cached state and clears check_queued_at.
  # Returns the created OrganizationDomainCheck.
  def record_check!(outcome:, message:)
    success = outcome == "matched"
    result = success ? "success" : "failure"
    checked_at = Time.current
    self.class.transaction(requires_new: true) do
      lock!
      # Not through the checks association: a rolled-back create would stay
      # cached on it (e.g. when the verified-domain index rejects the update).
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

  # Only the stored, validated row is ever checked.
  def ensure_verifiable!
    raise InvalidDomain, "domain has unsaved changes" if new_record? || changed?
    # Avoids a pointless DNS request; record_check!'s lock! is the real guard.
    raise DeletedDomain, "domain has been deleted" if destroyed? || !self.class.exists?(id)
    raise InvalidDomain, "stored domain is invalid" unless Name.valid?(domain)
  end

  # If the verified-domain unique index rejects marking this domain verified,
  # record_check!'s transaction rolls the check back and a failure is recorded
  # instead. A row deleted during the lookup raises DeletedDomain, recording nothing.
  def record_verification(result)
    record_check!(outcome: result.outcome, message: result.message)
  rescue ActiveRecord::RecordNotUnique => e
    raise unless e.message.include?("index_organization_domains_on_domain_verified")

    record_check!(outcome: "other_error", message: "Another organization has already verified this domain.")
  rescue ActiveRecord::RecordNotFound
    raise DeletedDomain, "domain was deleted during the check"
  end

  # The only changes made to the owner's input; anything else invalid is an error.
  def normalize_domain
    self.domain = domain.strip.downcase if domain.is_a?(String)
  end

  # Inside the insert's transaction (and after any token retry succeeded), so a
  # failed add records no event and a retry never duplicates it.
  # actor_gid is nil outside a web request (console, jobs), where Current.user is unset.
  def record_added_event
    organization.record_event!(Events::OrganizationEvent::DOMAIN_ADDED, domain:, txt_record_value:, actor_gid: Current.user&.to_gid)
  end

  def generate_token
    self.token = SecureRandom.urlsafe_base64(32)
  end

  # One owner-facing message; every broken rule is kept in errors.details.
  def domain_name_is_valid
    rules = Name.errors_for(domain)
    errors.add(:domain, :invalid_format, rules:) if rules.any?
  end
end
