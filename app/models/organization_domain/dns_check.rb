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
  # Overall budget (seconds) after which the optional SOA / wrong-name probes are
  # skipped. The TXT lookup itself always runs.
  BUDGET = 5
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
    # Only the stored row is ever queried: refuse unsaved or modified records.
    raise InvalidDomain, "domain has unsaved changes" if @domain.new_record? || @domain.changed?
    raise DeletedDomain, "domain has been removed" if @domain.destroyed? || !OrganizationDomain.exists?(@domain.id)
    raise InvalidDomain, "stored domain is invalid" unless OrganizationDomain::Name.valid?(@domain.domain)

    code, message = lookup
    record(code, message)
  end

  private

  def lookup
    with_resolver { |dns| classify(dns) }
  rescue Resolv::ResolvError => e
    return ["timeout", describe(e)] if e.message.include?("DNS resolv timeout")

    unknown(e)
  rescue SystemCallError, SocketError, IOError => e
    ["resolver_unavailable", describe(e)]
  rescue StandardError => e
    unknown(e)
  end

  def unknown(error)
    Rails.error.report(error, handled: true)
    ["unknown_error", describe(error)]
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
    @started_at = monotonic_now
    values = txt_values(dns, challenge_name)
    return classify_empty(dns) if values.empty?

    ours = @domain.txt_record_value
    return [nil, nil] if values.include?(ours)

    seen = truncate("TXT values seen: #{values.inspect}")
    return ["value_quoted", seen] if values.any? { |v| v.delete('"').strip == ours }
    return ["token_mismatch", seen] if values.any? { |v| v.delete('"').strip.start_with?(OrganizationDomain::TXT_VALUE_PREFIX) }

    ["value_mismatch", seen]
  end

  def classify_empty(dns)
    not_found = ["record_not_found", "No TXT records found at #{challenge_name}"]
    return skipped(not_found) if budget_spent?

    # Probes get a shorter timeout than the main lookup.
    dns.timeouts = PROBE_TIMEOUT unless @resolver
    # Resolv only returns records owned by the queried name, so a subdomain has no
    # SOA of its own; check the registrable domain instead.
    return ["domain_not_found", "No SOA record found for #{zone}"] if dns.getresources(absolute(zone), SOA).empty?

    wrong = nil
    wrong_name_probes.each do |name|
      return skipped(not_found) if budget_spent?

      (wrong = name) && break if txt_values(dns, name).include?(@domain.txt_record_value)
    end
    return ["record_at_wrong_name", "Value found at #{wrong} instead of #{challenge_name}"] if wrong

    not_found
  end

  def skipped(not_found)
    [not_found.first, "#{not_found.last} (further checks skipped: time budget spent)"]
  end

  def budget_spent? = monotonic_now - @started_at >= BUDGET

  def monotonic_now = Process.clock_gettime(Process::CLOCK_MONOTONIC)

  def zone
    PublicSuffix.domain(apex, default_rule: nil) || apex
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

  IPV4 = /\b\d{1,3}(?:\.\d{1,3}){3}(?::\d+)?\b/
  # Any run of address-ish characters containing a colon; deliberately permissive.
  COLON_TOKEN = /[\w:.%\[\]]*:[\w:.%\[\]]*/
  CONSTANT_PATH = /\A[A-Z]\w*(?:::[A-Z]\w*)+\z/
  CLOCK_TIME = /\A\d{1,2}:\d{2}(?::\d{2})?\z/

  # error_message is shown to owners: never store resolver addresses.
  # Redaction fails closed: a colon-bearing token is redacted unless it clearly
  # is a Ruby constant path or a clock time (and is not a valid IP address).
  def describe(error)
    message = error.message.gsub(COLON_TOKEN) { |token| keep_token?(token) ? token : "[redacted]" }
      .gsub(IPV4, "[redacted]")
    truncate("#{error.class}: #{message}")
  end

  def keep_token?(token)
    core = token.sub(/[.:]+\z/, "")
    return true unless core.include?(":")
    return false if ip_address?(core)

    core.match?(CONSTANT_PATH) || core.match?(CLOCK_TIME)
  end

  def ip_address?(core)
    address = core.sub(/\A\[(.*)\](?::\d+)?\z/, '\\1').sub(/%.*\z/, "")
    IPAddr.new(address)
    true
  rescue IPAddr::Error
    false
  end

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
  # The row is locked and re-read first; if it was deleted during the lookup
  # DeletedDomain is raised and nothing is recorded.
  def record_success
    persist(result: "success", verified: true)
  end

  def record_failure(code, message)
    persist(result: "failure", error_code: code, error_message: message, verified: false)
  end

  def persist(verified:, **attributes)
    checked_at = Time.current
    OrganizationDomain.transaction(requires_new: true) do
      @domain.lock!

      check = OrganizationDomainCheck.create!(organization_domain: @domain, checked_at:, **attributes)
      @domain.update_columns(verified_at: (checked_at if verified), last_checked_at: checked_at,
        last_check_result: attributes[:result], updated_at: checked_at)
      check
    end
  rescue ActiveRecord::RecordNotFound
    raise DeletedDomain, "domain was removed during the check"
  end
end
