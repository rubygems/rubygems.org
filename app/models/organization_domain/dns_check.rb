# frozen_string_literal: true

class OrganizationDomain::DnsCheck
  Result = Data.define(:outcome, :message)

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
  rescue Timeout::Error
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
