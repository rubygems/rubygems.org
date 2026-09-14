# frozen_string_literal: true

# Checks one organization's claimed domain for the TXT record proving control
# of it, and maintains `dns_verified_at`. See Organization::DnsVerification for
# the record format. Enqueued by VerifyOrganizationDomainsJob.
class VerifyOrganizationDomainJob < ApplicationJob
  queue_as "stats"

  # The organization was deleted between the sweep and this job; there is
  # nothing left to verify, and it isn't worth reporting.
  discard_on ActiveJob::DeserializationError

  # Per-query timeout, then one retry, in seconds.
  RESOLV_TIMEOUTS = [3, 5].freeze

  # A resolver failure says nothing about whether the record exists, so it
  # leaves any existing verification alone rather than revoking it.
  RESOLV_ERRORS = [Resolv::ResolvError, Resolv::ResolvTimeout].freeze

  def perform(organization:)
    # The domain may have been cleared, or another job may have checked it,
    # between the sweep and now.
    return unless organization.should_verify_dns?

    if txt_records(organization.dns_txt_record_name).include?(organization.dns_txt_record_value)
      logger.info "verified organization domain", organization: organization.handle, domain: organization.domain
      organization.dns_verification_succeeded!
      StatsD.increment("organization_domains.verify.verified")
    else
      logger.info "organization domain TXT record not found", organization: organization.handle, domain: organization.domain
      organization.dns_verification_failed!
      StatsD.increment("organization_domains.verify.unverified")
    end
  rescue *RESOLV_ERRORS => e
    logger.info "organization domain lookup failed (#{e.class}: #{e.message})",
      organization: organization.handle, domain: organization.domain
    organization.dns_verification_inconclusive!
    StatsD.increment("organization_domains.verify.inconclusive")
  end

  private

  # A TXT record's value is transmitted as one or more character-strings of at
  # most 255 bytes; the record's value is their concatenation.
  def txt_records(domain)
    resolver.getresources(domain, Resolv::DNS::Resource::IN::TXT).map { |record| record.strings.join }
  end

  def resolver
    @resolver ||= Resolv::DNS.new.tap { |dns| dns.timeouts = RESOLV_TIMEOUTS }
  end
end
