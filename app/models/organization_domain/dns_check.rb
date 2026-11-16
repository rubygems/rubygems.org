# frozen_string_literal: true

# Makes one DNS TXT request and interprets the response. It knows nothing about
# records: OrganizationDomain#verify! decides whether a check may run and
# records the Result.
#
# Looks up TXT at the absolute `name` and compares each value (strings joined,
# whitespace stripped) with `expected_value`. Returns a Result with one of the
# OrganizationDomainCheck outcomes: matched, record_not_found, record_mismatch or
# other_error. Values found in DNS are never included in the message.
#
# `resolver:` is the test seam: any object responding to
# `getresources(absolute_name, resource_class)` (like Resolv::DNS). An injected
# resolver is used as-is and is not closed or reconfigured.
class OrganizationDomain::DnsCheck
  Result = Data.define(:outcome, :message)

  # Seconds; caps the whole lookup.
  TIMEOUT = 30
  TXT = Resolv::DNS::Resource::IN::TXT

  def self.call(name:, expected_value:, resolver: nil)
    new(name:, expected_value:, resolver:).call
  end

  def initialize(name:, expected_value:, resolver: nil)
    @name = name
    @expected_value = expected_value
    @resolver = resolver
  end

  def call
    values = Timeout.timeout(TIMEOUT) { with_resolver { |dns| txt_values(dns) } }

    if values.empty?
      Result.new(outcome: "record_not_found", message: "No TXT record found at #{@name}.")
    elsif values.include?(@expected_value)
      Result.new(outcome: "matched", message: "Found a matching TXT record at #{@name}.")
    else
      Result.new(outcome: "record_mismatch", message: "A TXT record exists at #{@name} but its value does not match.")
    end
  rescue Timeout::Error # includes Resolv::ResolvTimeout
    Result.new(outcome: "other_error", message: "DNS lookup timed out after #{TIMEOUT} seconds.")
  rescue StandardError => e
    Rails.error.report(e, handled: true)
    Result.new(outcome: "other_error",
      message: "#{e.class}: #{e.message}".truncate(OrganizationDomainCheck::MAX_MESSAGE_LENGTH))
  end

  private

  def with_resolver(&)
    return yield @resolver if @resolver

    Resolv::DNS.open do |dns|
      dns.timeouts = TIMEOUT
      yield dns
    end
  end

  def txt_values(dns)
    dns.getresources("#{@name}.", TXT).map { |record| record.strings.join.strip }
  end
end
