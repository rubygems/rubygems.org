# frozen_string_literal: true

# Domain ownership verification for organizations, in the style of GitHub's
# verified organization domains.
#
# An organization claims a domain and is issued a random token. The owner
# proves control of the domain by publishing a TXT record at the domain apex
# containing `rubygems-verification=<token>`. VerifyOrganizationDomainsJob
# sweeps claimed domains on a schedule and maintains `dns_verified_at`.
#
# Two organizations may claim the same domain: each is issued its own token,
# and a domain apex can hold both TXT records, so only the party that can
# actually edit the zone can verify either claim.
module Organization::DnsVerification
  extend ActiveSupport::Concern

  TXT_RECORD_PREFIX = "rubygems-verification="

  # How often the sweep re-checks a claimed domain.
  CHECK_INTERVAL = 6.hours

  # How long a successful check counts for. A verification lapses on its own
  # once no check has succeeded inside this window, so verification can never
  # outlive the job that maintains it -- if the sweep stops running, every
  # verification expires rather than persisting indefinitely.
  VALIDITY = 1.week

  included do
    # A claimed domain is optional, but once present it has to be a real
    # registrable domain we can actually query.
    validates :domain, allow_nil: true,
      length: { maximum: 253 },
      format: { with: EmailDomainNormalization::DOMAIN_FORMAT }
    validate :domain_must_be_registrable

    before_validation :normalize_domain
    before_validation :reset_dns_verification, if: :domain_changed?

    scope :with_domain, -> { where.not(domain: nil) }
    scope :dns_verified, -> { with_domain.where(dns_verified_at: VALIDITY.ago..) }
    scope :pending_dns_verification, lambda {
      with_domain.where(dns_last_checked_at: nil)
        .or(with_domain.where(dns_last_checked_at: ...CHECK_INTERVAL.ago))
    }
  end

  def dns_verified?
    return false unless (verified_at = dns_verified_at.presence)

    verified_at.after?(VALIDITY.ago)
  end

  def should_verify_dns?
    return false if domain.blank?

    dns_last_checked_at.nil? || dns_last_checked_at.before?(CHECK_INTERVAL.ago)
  end

  # The name of the TXT record to look up: the domain apex.
  def dns_txt_record_name
    domain
  end

  # The value the TXT record has to contain for this organization.
  def dns_txt_record_value
    return if dns_verification_token.blank?

    "#{TXT_RECORD_PREFIX}#{dns_verification_token}"
  end

  def dns_verification_succeeded!
    update!(dns_verified_at: Time.current, dns_last_checked_at: Time.current)
  end

  # The record is gone (or was never published): drop any existing
  # verification. This is what makes removing the TXT record revoke the
  # organization's claim.
  def dns_verification_failed!
    update!(dns_verified_at: nil, dns_last_checked_at: Time.current)
  end

  # The resolver failed to answer, which says nothing about the record. Record
  # the attempt but leave an existing verification intact so a resolver blip
  # doesn't revoke a legitimate claim.
  def dns_verification_inconclusive!
    update!(dns_last_checked_at: Time.current)
  end

  private

  def normalize_domain
    self.domain = domain.presence&.strip&.downcase
  end

  # Claiming a different domain invalidates everything proven about the old
  # one: a fresh token is issued and the organization starts out unverified.
  # Without this an organization could verify a domain it controls and then
  # point `domain` at someone else's while staying verified.
  def reset_dns_verification
    self.dns_verified_at = nil
    self.dns_last_checked_at = nil
    self.dns_verification_token = domain.present? ? SecureRandom.hex(20) : nil
  end

  # `default_rule: nil` turns off PublicSuffix's wildcard fallback, which
  # otherwise accepts any invented TLD ("foo.internal", "foo.notatld") as a
  # registrable domain. We only want domains under a TLD that actually exists.
  def domain_must_be_registrable
    return if domain.blank?
    # The format check already rejected this; one message is enough.
    return if errors.include?(:domain)
    return if PublicSuffix.valid?(domain, default_rule: nil)

    # Without the wildcard fallback these are two different mistakes: a TLD
    # that does not exist, and a domain that is itself a public suffix.
    errors.add(:domain, PublicSuffix.valid?(domain) ? :unknown_tld : :public_suffix)
  end
end
