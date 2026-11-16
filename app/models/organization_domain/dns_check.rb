# frozen_string_literal: true

# Runs one synchronous DNS TXT check for an OrganizationDomain and records it.
#
# Matches only the domain row's own txt_record_value. DNS names are built from
# the stored, validated domain only, and are passed to Resolv as absolute names.
#
# `resolver:` is the test seam: any object responding to
# `getresources(absolute_name, resource_class)` (like Resolv::DNS). An injected
# resolver is used as-is and is not closed or reconfigured.
class OrganizationDomain::DnsCheck
  class Error < StandardError; end
  class InvalidDomain < Error; end
  class DeletedDomain < Error; end

  TIMEOUT = 2
  PROBE_TIMEOUT = 1
  MAX_NAME_LENGTH = 253
  MAX_MESSAGE_LENGTH = 500
  TXT = Resolv::DNS::Resource::IN::TXT
  SOA = Resolv::DNS::Resource::IN::SOA

  def self.call(domain, resolver: nil)
    new(domain, resolver:).call
  end

  def initialize(domain, resolver: nil)
    @domain = domain
    @resolver = resolver
  end

  def call
    raise DeletedDomain, "domain has been removed" if @domain.deleted_at.present?
    raise InvalidDomain, "stored domain is invalid" unless OrganizationDomain::Name.valid?(@domain.domain)

    code, message = lookup
    record(code, message)
  end

  private

  def lookup
    with_resolver { |dns| classify(dns) }
  rescue Resolv::ResolvError => e
    [e.message.include?("DNS resolv timeout") ? "timeout" : "unknown_error", describe(e)]
  rescue SystemCallError, SocketError, IOError => e
    ["resolver_unavailable", describe(e)]
  rescue StandardError => e
    ["unknown_error", describe(e)]
  end

  def with_resolver
    return yield @resolver if @resolver

    dns = Resolv::DNS.new(Resolv::DNS::Config.default_config_hash.merge(raise_timeout_errors: true))
    dns.timeouts = TIMEOUT
    begin
      yield dns
    ensure
      dns.close
    end
  end

  # Returns [nil, nil] on success, otherwise [error_code, error_message].
  def classify(dns)
    values = txt_values(dns, challenge_name)
    return classify_empty(dns) if values.empty?

    ours = @domain.txt_record_value
    return [nil, nil] if values.include?(ours)

    seen = truncate("TXT values seen: #{values.inspect}")
    return ["value_quoted", seen] if values.any? { |v| v.delete('"').strip == ours }
    return ["token_mismatch", seen] if values.any? { |v| v.start_with?(OrganizationDomain::TXT_VALUE_PREFIX) }

    ["value_mismatch", seen]
  end

  def classify_empty(dns)
    # Probes get a shorter timeout than the main lookup to keep the total bounded.
    dns.timeouts = PROBE_TIMEOUT unless @resolver
    return ["domain_not_found", "No SOA record found for #{apex}"] if dns.getresources(absolute(apex), SOA).empty?

    wrong = wrong_name_probes.find { |name| txt_values(dns, name).include?(@domain.txt_record_value) }
    return ["record_at_wrong_name", "Value found at #{wrong} instead of #{challenge_name}"] if wrong

    ["record_not_found", "No TXT records found at #{challenge_name}"]
  end

  def txt_values(dns, name)
    dns.getresources(absolute(name), TXT).map { |record| record.strings.join.strip }
  end

  def wrong_name_probes
    doubled = "#{challenge_name}.#{apex}"
    [apex, (doubled if absolute(doubled).length <= MAX_NAME_LENGTH)].compact
  end

  def apex = @domain.domain

  def challenge_name = @domain.txt_record_name

  def absolute(name) = "#{name}."

  def describe(error) = truncate("#{error.class}: #{error.message}")

  def truncate(text) = text.truncate(MAX_MESSAGE_LENGTH)

  def record(code, message)
    return record_success if code.nil?

    record_failure(code, message)
  rescue ActiveRecord::RecordNotUnique => e
    raise unless e.message.include?("index_organization_domains_on_domain_verified")

    record_failure("already_verified", "Another organization holds #{apex} as a verified domain")
  end

  # One transaction: if the verified-domain unique index rejects the update,
  # the check row is rolled back too and a failure is recorded instead.
  def record_success
    checked_at = Time.current
    OrganizationDomain.transaction(requires_new: true) do
      check = OrganizationDomainCheck.create!(organization_domain: @domain, checked_at:, result: "success")
      @domain.update!(verified_at: checked_at, last_checked_at: checked_at, last_check_result: "success")
      check
    end
  end

  def record_failure(code, message)
    checked_at = Time.current
    OrganizationDomain.transaction(requires_new: true) do
      check = OrganizationDomainCheck.create!(organization_domain: @domain, checked_at:, result: "failure", error_code: code, error_message: message)
      @domain.update!(verified_at: nil, last_checked_at: checked_at, last_check_result: "failure")
      check
    end
  end
end
