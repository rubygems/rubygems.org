# frozen_string_literal: true

require "test_helper"
require "helpers/fake_dns_resolver"

class OrganizationDomain::DnsCheckTest < ActiveSupport::TestCase
  TXT = Resolv::DNS::Resource::IN::TXT
  SOA = Resolv::DNS::Resource::IN::SOA

  setup do
    @domain = create(:organization_domain, domain: "example.com")
    @name = "_rubygems-challenge.example.com."
  end

  def soa
    SOA.new(Resolv::DNS::Name.create("ns.example.com."), Resolv::DNS::Name.create("h.example.com."), 1, 1, 1, 1, 1)
  end

  def txt(*strings)
    TXT.new(*strings)
  end

  def resolver(answers = {})
    @resolver = FakeDnsResolver.new({ ["example.com.", SOA] => [soa] }.merge(answers))
  end

  def verify(answers = {}, domain: @domain)
    domain.verify!(resolver: resolver(answers))
  end

  def assert_failure(check, code, domain: @domain, message: nil)
    assert_predicate check, :failure?
    assert_equal code.to_s, check.error_code
    assert_equal message, check.error_message if message.is_a?(String)
    assert_match message, check.error_message if message.is_a?(Regexp)
    domain.reload

    assert_nil domain.verified_at
    assert_equal "failure", domain.last_check_result
    assert_equal check.checked_at.to_i, domain.last_checked_at.to_i
  end

  context "success" do
    should "record a success and verify the domain" do
      check = verify({ [@name, TXT] => [txt(@domain.txt_record_value)] })

      assert_predicate check, :success?
      assert_nil check.error_code
      assert_nil check.error_message
      assert_predicate check, :persisted?
      assert_equal @domain, check.organization_domain
      @domain.reload

      assert_equal check.checked_at.to_i, @domain.verified_at.to_i
      assert_equal check.checked_at.to_i, @domain.last_checked_at.to_i
      assert_equal "success", @domain.last_check_result
    end

    should "join split strings with no separator" do
      value = @domain.txt_record_value

      assert_predicate verify({ [@name, TXT] => [txt(value[0, 10], value[10..])] }), :success?
    end

    should "match when any value at the name equals ours" do
      check = verify({ [@name, TXT] => [txt("v=spf1 -all"), txt("rubygems-verification=other"), txt(@domain.txt_record_value)] })

      assert_predicate check, :success?
    end

    should "strip surrounding whitespace" do
      assert_predicate verify({ [@name, TXT] => [txt("  #{@domain.txt_record_value}\n")] }), :success?
    end

    should "only query absolute names" do
      verify({ [@name, TXT] => [txt(@domain.txt_record_value)] })

      assert_equal [[@name, TXT]], @resolver.queries
    end
  end

  context "failures" do
    should "record timeout" do
      check = verify({ [@name, TXT] => Resolv::ResolvError.new("DNS resolv timeout: #{@name}") })

      assert_failure check, :timeout, message: /DNS resolv timeout/
      assert_equal :lookup_failed, check.error_group
    end

    should "record resolver_unavailable for socket errors" do
      [Errno::ENETUNREACH.new, SocketError.new("boom"), IOError.new("closed")].each do |error|
        check = verify({ [@name, TXT] => error })

        assert_failure check, :resolver_unavailable, message: /#{Regexp.escape(error.class.name)}/
        assert_equal :lookup_failed, check.error_group
      end
    end

    should "record domain_not_found when the name and apex SOA are empty" do
      check = verify({ ["example.com.", SOA] => [] })

      assert_failure check, :domain_not_found, message: "No SOA record found for example.com"
      assert_equal :record_missing, check.error_group
    end

    should "record record_not_found when the apex resolves but there is no TXT" do
      check = verify

      assert_failure check, :record_not_found, message: "No TXT records found at _rubygems-challenge.example.com"
      assert_equal :record_missing, check.error_group
    end

    should "record record_at_wrong_name for a value at the apex" do
      check = verify({ ["example.com.", TXT] => [txt(@domain.txt_record_value)] })

      assert_failure check, :record_at_wrong_name, message: "Value found at example.com instead of _rubygems-challenge.example.com"
      assert_equal :record_missing, check.error_group
    end

    should "record record_at_wrong_name for a value at the doubled name" do
      check = verify({ ["_rubygems-challenge.example.com.example.com.", TXT] => [txt(@domain.txt_record_value)] })

      assert_failure check, :record_at_wrong_name, message: /Value found at _rubygems-challenge.example.com.example.com instead/
    end

    should "skip the doubled-name probe when it would be too long" do
      long = "#{'a' * 60}.#{'b' * 60}.#{'c' * 60}.example.com"
      domain = create(:organization_domain)
      OrganizationDomain.where(id: domain.id).update_all(domain: long)
      domain.reload
      OrganizationDomain::Name.stubs(:valid?).returns(true)
      res = FakeDnsResolver.new({ ["example.com.", SOA] => [soa] })

      check = domain.verify!(resolver: res)

      assert_equal "record_not_found", check.error_code
      assert_equal 3, res.queries.size
      assert(res.queries.none? { |(name, _)| name.start_with?("_rubygems-challenge.#{long}.#{long}") })
    end

    should "record value_quoted" do
      check = verify({ [@name, TXT] => [txt(%("#{@domain.txt_record_value}"))] })

      assert_failure check, :value_quoted, message: /TXT values seen/
      assert_equal :record_mismatch, check.error_group
    end

    should "record token_mismatch for a different token and show the values seen" do
      check = verify({ [@name, TXT] => [txt("rubygems-verification=nope")] })

      assert_failure check, :token_mismatch, message: /rubygems-verification=nope/
      assert_equal :record_mismatch, check.error_group
      refute_match(/different|removed/, check.error_message)
    end

    should "record value_mismatch when no value looks like ours" do
      check = verify({ [@name, TXT] => [txt("v=spf1 -all")] })

      assert_failure check, :value_mismatch, message: /v=spf1 -all/
      assert_equal :record_mismatch, check.error_group
    end

    should "truncate the values seen in error_message" do
      check = verify({ [@name, TXT] => [txt("x" * 5000)] })

      assert_operator check.error_message.length, :<=, 500
    end

    should "record unknown_error for anything else" do
      check = verify({ [@name, TXT] => RuntimeError.new("weird") })

      assert_failure check, :unknown_error, message: "RuntimeError: weird"
      assert_equal :unknown, check.error_group
    end

    should "report unknown_error to Rails.error" do
      Rails.error.expects(:report).with { |e, opts| e.message == "weird" && opts[:handled] == true }

      verify({ [@name, TXT] => RuntimeError.new("weird") })
    end

    should "redact resolver addresses from the stored message" do
      error = Errno::ECONNREFUSED.new("connect(2) for 10.0.0.2:53 and [2001:db8::1]:53 and fe80::1")
      check = verify({ [@name, TXT] => error })

      assert_failure check, :resolver_unavailable
      assert_includes check.error_message, "[redacted]"
      refute_match(/10\.0\.0\.2|53|2001|fe80/, check.error_message)

      check = verify({ [@name, TXT] => RuntimeError.new("dial 192.168.1.1:53") })

      assert_equal "RuntimeError: dial [redacted]", check.error_message
    end

    should "redact every IP address shape, failing closed" do
      {
        "read from fe80::1: timeout" => "read from [redacted] timeout",
        "[2001:db8::1]:53: refused" => "[redacted] refused",
        "[fe80::1%eth0]:53" => "[redacted]",
        "fe80::1%eth0" => "[redacted]",
        "connect(2) for 10.0.0.2:53" => "connect(2) for [redacted]",
        "::1" => "[redacted]",
        "2001:db8::1" => "[redacted]",
        "[2001:db8::1]:53" => "[redacted]"
      }.each do |input, expected|
        check = verify({ [@name, TXT] => RuntimeError.new(input) })

        assert_equal "RuntimeError: #{expected}", check.error_message, input
      end
    end

    should "keep class names and times that are not addresses" do
      ["Errno::ECONNREFUSED", "Resolv::DNS::Resource::IN::TXT", "12:30:45", "at 09:15"].each do |input|
        check = verify({ [@name, TXT] => RuntimeError.new(input) })

        assert_equal "RuntimeError: #{input}", check.error_message, input
      end
    end

    should "record token_mismatch for a quoted value with a different token" do
      check = verify({ [@name, TXT] => [txt('"rubygems-verification=nope"')] })

      assert_failure check, :token_mismatch
    end

    should "treat a non-timeout ResolvError as unknown_error" do
      check = verify({ [@name, TXT] => Resolv::ResolvError.new("other") })

      assert_failure check, :unknown_error
    end

    should "record already_verified and leave the other org's verification untouched" do
      other = create(:organization_domain, :verified, domain: "example.com")
      other_verified_at = other.reload.verified_at
      value = @domain.txt_record_value

      assert_no_difference -> { other.reload.checks.count } do
        assert_difference -> { @domain.checks.count }, 1 do
          check = verify({ [@name, TXT] => [txt(value)] })

          assert_failure check, :already_verified, message: /Another organization holds example.com/
          assert_equal :conflict, check.error_group
        end
      end
      assert_equal other_verified_at, other.reload.verified_at
      assert_equal 1, OrganizationDomain.verified.where(domain: "example.com").count
    end
  end

  context "latest check decides" do
    should "un-verify a previously verified domain on a later failure" do
      verify({ [@name, TXT] => [txt(@domain.txt_record_value)] })

      assert_predicate @domain.reload, :verified?

      check = verify({ [@name, TXT] => [txt("gone")] })

      assert_failure check, :value_mismatch
      refute_predicate @domain.reload, :verified?
      assert_equal 2, @domain.checks.count
    end
  end

  context "tokens" do
    should "only accept each row's own token across orgs" do
      b = create(:organization_domain, domain: "example.com")
      answers = { [@name, TXT] => [txt(@domain.txt_record_value)] }

      assert_failure verify(answers, domain: b), :token_mismatch, domain: b
      assert_predicate verify(answers, domain: @domain), :success?
      refute_predicate b.reload, :verified?
    end

    should "not accept the token of a removed and re-added domain" do
      old_value = @domain.txt_record_value
      @domain.remove!
      fresh = create(:organization_domain, domain: "example.com", organization: @domain.organization)

      assert_failure verify({ [@name, TXT] => [txt(old_value)] }, domain: fresh), :token_mismatch, domain: fresh
      assert_predicate verify({ [@name, TXT] => [txt(fresh.txt_record_value)] }, domain: fresh), :success?
    end
  end

  context "subdomains" do
    should "check the registrable domain's SOA, not the subdomain's" do
      domain = create(:organization_domain, domain: "eng.example.com")
      res = FakeDnsResolver.new({ ["example.com.", SOA] => [soa] })

      check = domain.verify!(resolver: res)

      assert_failure check, :record_not_found, domain: domain
      assert_includes res.queries, ["example.com.", SOA]
    end

    should "record domain_not_found when the registrable domain has no SOA" do
      domain = create(:organization_domain, domain: "eng.example.com")

      assert_failure domain.verify!(resolver: FakeDnsResolver.new), :domain_not_found, domain: domain,
        message: "No SOA record found for example.com"
    end
  end

  context "time budget" do
    should "skip the SOA and probes once the budget is spent, still running the TXT lookup" do
      OrganizationDomain::DnsCheck.any_instance.stubs(:monotonic_now).returns(0, OrganizationDomain::DnsCheck::BUDGET + 1)
      res = FakeDnsResolver.new

      check = @domain.verify!(resolver: res)

      assert_failure check, :record_not_found, message: /time budget spent/
      assert_equal [[@name, TXT]], res.queries
    end

    should "skip remaining probes when the budget runs out mid-way" do
      budget = OrganizationDomain::DnsCheck::BUDGET
      OrganizationDomain::DnsCheck.any_instance.stubs(:monotonic_now).returns(0, 0, 0, budget)
      res = FakeDnsResolver.new({ ["example.com.", SOA] => [soa] })

      check = @domain.verify!(resolver: res)

      assert_failure check, :record_not_found, message: /time budget spent/
      assert_equal [[@name, TXT], ["example.com.", SOA], ["example.com.", TXT]], res.queries
    end
  end

  context "stored-row guards" do
    should "refuse a record with unsaved changes without querying or recording" do
      @domain.verified_at = Time.current
      res = FakeDnsResolver.new

      assert_no_difference "OrganizationDomainCheck.count" do
        assert_raises(OrganizationDomain::DnsCheck::InvalidDomain) { @domain.verify!(resolver: res) }
      end
      assert_empty res.queries
      assert_nil OrganizationDomain.find(@domain.id).verified_at
    end

    should "not verify a domain removed during the lookup" do
      value = @domain.txt_record_value
      res = FakeDnsResolver.new({ [@name, TXT] => [txt(value)] })
      id = @domain.id
      res.define_singleton_method(:getresources) do |*args|
        OrganizationDomain.find(id).remove!
        super(*args)
      end

      assert_no_difference "OrganizationDomainCheck.count" do
        assert_raises(OrganizationDomain::DnsCheck::DeletedDomain) { @domain.verify!(resolver: res) }
      end
      assert_nil OrganizationDomain.find(id).verified_at
    end
  end

  context "guards" do
    should "raise without querying or recording when the domain is invalid" do
      res = FakeDnsResolver.new
      OrganizationDomain::Name.stubs(:valid?).returns(false)

      assert_no_difference "OrganizationDomainCheck.count" do
        assert_raises(OrganizationDomain::DnsCheck::InvalidDomain) { @domain.verify!(resolver: res) }
      end
      assert_empty res.queries
    end

    should "raise without querying or recording for a deleted domain" do
      @domain.remove!
      res = FakeDnsResolver.new

      assert_no_difference "OrganizationDomainCheck.count" do
        assert_raises(OrganizationDomain::DnsCheck::DeletedDomain) { @domain.verify!(resolver: res) }
      end
      assert_empty res.queries
    end
  end

  context "default resolver" do
    should "keep the system nameservers, raise timeout errors, close, and use absolute names" do
      config = nil
      fake = FakeDnsResolver.new({ ["example.com.", SOA] => [soa] })
      fake.expects(:close).at_least_once
      fake.expects(:timeouts=).with(OrganizationDomain::DnsCheck::TIMEOUT)
      fake.expects(:timeouts=).with(OrganizationDomain::DnsCheck::PROBE_TIMEOUT)
      Resolv::DNS.stubs(:new).with { |c| config = c }.returns(fake)

      check = @domain.verify!

      assert_equal "record_not_found", check.error_code
      assert_equal Resolv::DNS::Config.default_config_hash[:nameserver], config[:nameserver]
      assert config[:raise_timeout_errors]
      assert(fake.queries.all? { |(name, _)| name.end_with?(".") })
    end

    should "close the resolver even when the lookup raises" do
      fake = FakeDnsResolver.new({ [@name, TXT] => Errno::ECONNREFUSED })
      fake.expects(:close)
      Resolv::DNS.stubs(:new).returns(fake)

      assert_equal "resolver_unavailable", @domain.verify!.error_code
    end
  end
end
