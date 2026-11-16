# frozen_string_literal: true

# Runs one DNS TXT check for an OrganizationDomain and records it.
#
# Matches only the domain row's own txt_record_value. The DNS name is built from
# the stored, validated domain only, and is passed to Resolv as an absolute name.
# Exactly four outcomes are stored (see OrganizationDomainCheck): matched,
# record_not_found, record_mismatch and other_error.
#
# `resolver:` is the test seam: any object responding to
# `getresources(absolute_name, resource_class)` (like Resolv::DNS). An injected
# resolver is used as-is and is not closed or reconfigured.
class OrganizationDomain::DnsCheck
  class Error < StandardError; end
  class InvalidDomain < Error; end
  class DeletedDomain < Error; end

  # Seconds; caps the whole lookup.
  TIMEOUT = 30
  MAX_MESSAGE_LENGTH = 500
  TXT = Resolv::DNS::Resource::IN::TXT

  def self.call(domain, resolver: nil)
    new(domain, resolver:).call
  end

  def initialize(domain, resolver: nil)
    @domain = domain
    @resolver = resolver
  end

  def call
    # Only the stored row is ever queried: refuse unsaved or modified records.
    raise InvalidDomain, "domain has unsaved changes" if @domain.new_record? || @domain.changed?
    # Only avoids a pointless DNS query; the lock! in persist is the real guard.
    raise DeletedDomain, "domain has been removed" if @domain.destroyed? || !OrganizationDomain.exists?(@domain.id)
    raise InvalidDomain, "stored domain is invalid" unless OrganizationDomain::Name.valid?(@domain.domain)

    outcome, message = lookup
    record(outcome, message)
  end

  private

  # Returns [outcome, message].
  def lookup
    values = Timeout.timeout(TIMEOUT) { with_resolver { |dns| txt_values(dns) } }
    name = @domain.txt_record_name

    if values.empty?
      ["record_not_found", "No TXT record found at #{name}."]
    elsif values.include?(@domain.txt_record_value)
      ["matched", "Found a matching TXT record at #{name}."]
    else
      # Never store what was found in DNS.
      ["record_mismatch", "A TXT record exists at #{name} but its value does not match."]
    end
  rescue Timeout::Error # includes Resolv::ResolvTimeout
    ["other_error", "DNS lookup timed out after #{TIMEOUT} seconds."]
  rescue StandardError => e
    Rails.error.report(e, handled: true)
    ["other_error", "#{e.class}: #{e.message}".truncate(MAX_MESSAGE_LENGTH)]
  end

  def with_resolver(&)
    return yield @resolver if @resolver

    Resolv::DNS.open do |dns|
      dns.timeouts = TIMEOUT
      yield dns
    end
  end

  def txt_values(dns)
    dns.getresources("#{@domain.txt_record_name}.", TXT).map { |record| record.strings.join.strip }
  end

  def record(outcome, message)
    persist(outcome:, message:)
  rescue ActiveRecord::RecordNotUnique => e
    raise unless e.message.include?("index_organization_domains_on_domain_verified")

    persist(outcome: "other_error", message: "Another organization has already verified this domain.")
  end

  # If the verified-domain unique index rejects the update, record_check!'s
  # transaction rolls the check back too and a failure is recorded instead. A row
  # deleted during the lookup raises DeletedDomain and nothing is recorded.
  def persist(outcome:, message:)
    @domain.record_check!(outcome:, message:)
  rescue ActiveRecord::RecordNotFound
    raise DeletedDomain, "domain was removed during the check"
  end
end
