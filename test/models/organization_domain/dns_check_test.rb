# frozen_string_literal: true

require "test_helper"
require "helpers/fake_dns_resolver"

class OrganizationDomain::DnsCheckTest < ActiveSupport::TestCase
  TXT = Resolv::DNS::Resource::IN::TXT

  setup do
    @domain = create(:organization_domain, domain: "example.com", check_queued_at: Time.current)
    @name = "_rubygems-challenge.example.com."
  end

  def txt(*strings)
    TXT.new(*strings)
  end

  def verify(answers = {}, domain: @domain)
    @resolver = FakeDnsResolver.new(answers)
    domain.verify!(resolver: @resolver)
  end

  def assert_failure(check, outcome, message: nil, domain: @domain)
    assert_predicate check, :failure?
    assert_equal outcome.to_s, check.outcome
    assert_equal message, check.message if message.is_a?(String)
    assert_match message, check.message if message.is_a?(Regexp)
    domain.reload

    assert_nil domain.verified_at
    assert_equal "failure", domain.last_check_result
    assert_equal check.checked_at.to_i, domain.last_checked_at.to_i
    assert_nil domain.check_queued_at
  end

  context "matched" do
    should "record a success and verify the domain" do
      check = verify({ [@name, TXT] => [txt(@domain.txt_record_value)] })

      assert_predicate check, :success?
      assert_equal "matched", check.outcome
      assert_equal "Found a matching TXT record at _rubygems-challenge.example.com.", check.message
      assert_predicate check, :persisted?
      @domain.reload

      assert_equal check.checked_at.to_i, @domain.verified_at.to_i
      assert_equal check.checked_at.to_i, @domain.last_checked_at.to_i
      assert_equal "success", @domain.last_check_result
      assert_nil @domain.check_queued_at
    end

    should "join split strings with no separator" do
      value = @domain.txt_record_value

      assert_predicate verify({ [@name, TXT] => [txt(value[0, 10], value[10..])] }), :success?
    end

    should "strip whitespace and accept any one of several values" do
      value = @domain.txt_record_value
      check = verify({ [@name, TXT] => [txt("other"), txt("  #{value}\n")] })

      assert_predicate check, :success?
    end

    should "query only the absolute challenge name for TXT" do
      verify({ [@name, TXT] => [txt(@domain.txt_record_value)] })

      assert_equal [[@name, TXT]], @resolver.queries
    end
  end

  context "record_not_found" do
    should "record a failure when there is no TXT record" do
      check = verify

      assert_failure check, :record_not_found, message: "No TXT record found at _rubygems-challenge.example.com."
    end
  end

  context "record_mismatch" do
    should "record a failure without storing the values found" do
      check = verify({ [@name, TXT] => [txt("rubygems-verification=SECRET-FOUND"), txt("other")] })

      assert_failure check, :record_mismatch,
        message: "A TXT record exists at _rubygems-challenge.example.com but its value does not match."
      refute_includes check.message, "SECRET-FOUND"
    end

    should "not accept a quoted value" do
      check = verify({ [@name, TXT] => [txt(%("#{@domain.txt_record_value}"))] })

      assert_failure check, :record_mismatch
    end
  end

  context "other_error" do
    should "record a timeout with the fixed message and not report it" do
      Rails.error.expects(:report).never
      check = verify({ [@name, TXT] => Timeout::Error.new("execution expired") })

      assert_failure check, :other_error, message: "DNS lookup timed out after 30 seconds."
    end

    should "treat a Resolv timeout as a timeout" do
      check = verify({ [@name, TXT] => Resolv::ResolvTimeout.new("x") })

      assert_failure check, :other_error, message: "DNS lookup timed out after 30 seconds."
    end

    should "cap the whole lookup with Timeout" do
      Timeout.expects(:timeout).with(OrganizationDomain::DnsCheck::TIMEOUT).raises(Timeout::Error)

      assert_failure verify, :other_error, message: "DNS lookup timed out after 30 seconds."
      assert_equal 30, OrganizationDomain::DnsCheck::TIMEOUT
    end

    should "record the class and message of any other exception and report it" do
      Rails.error.expects(:report).with { |e, opts| e.is_a?(SocketError) && opts == { handled: true } }
      check = verify({ [@name, TXT] => SocketError.new("boom") })

      assert_failure check, :other_error, message: "SocketError: boom"
    end

    should "truncate long messages to 500 characters" do
      check = verify({ [@name, TXT] => RuntimeError.new("x" * 1000) })

      assert_equal 500, check.message.length
    end

    should "record a failure when another organization already verified the domain" do
      other = create(:organization_domain, :verified, domain: "example.com")
      other_verified_at = other.reload.verified_at
      value = @domain.txt_record_value

      assert_no_difference -> { other.reload.checks.count } do
        assert_difference -> { @domain.checks.count }, 1 do
          check = verify({ [@name, TXT] => [txt(value)] })

          assert_failure check, :other_error, message: "Another organization has already verified this domain."
        end
      end
      assert_equal other_verified_at, other.reload.verified_at
    end
  end

  context "latest check decides" do
    should "un-verify a previously verified domain on a later failure" do
      assert_predicate verify({ [@name, TXT] => [txt(@domain.txt_record_value)] }), :success?
      check = verify

      assert_failure check, :record_not_found
      assert_equal %w[failure success], @domain.checks.pluck(:result)
    end
  end

  context "tokens" do
    should "not accept the token of a removed and re-added domain" do
      old_value = @domain.txt_record_value
      @domain.remove!(actor: create(:user))
      fresh = create(:organization_domain, domain: "example.com")

      assert_failure verify({ [@name, TXT] => [txt(old_value)] }, domain: fresh), :record_mismatch, domain: fresh
    end
  end

  context "guards" do
    should "refuse a record with unsaved changes without querying or recording" do
      @domain.verified_at = Time.current
      res = FakeDnsResolver.new

      assert_no_difference "OrganizationDomainCheck.count" do
        assert_raises(OrganizationDomain::DnsCheck::InvalidDomain) { @domain.verify!(resolver: res) }
      end
      assert_empty res.queries
    end

    should "refuse an invalid stored domain" do
      res = FakeDnsResolver.new
      OrganizationDomain::Name.stubs(:valid?).returns(false)

      assert_no_difference "OrganizationDomainCheck.count" do
        assert_raises(OrganizationDomain::DnsCheck::InvalidDomain) { @domain.verify!(resolver: res) }
      end
      assert_empty res.queries
    end

    should "raise without querying or recording for a destroyed domain" do
      @domain.remove!(actor: create(:user))
      res = FakeDnsResolver.new

      assert_no_difference "OrganizationDomainCheck.count" do
        assert_raises(OrganizationDomain::DnsCheck::DeletedDomain) { @domain.verify!(resolver: res) }
      end
      assert_empty res.queries
    end

    should "raise without querying or recording when the row was deleted elsewhere" do
      stale = OrganizationDomain.find(@domain.id)
      @domain.remove!(actor: create(:user))
      res = FakeDnsResolver.new

      assert_no_difference "OrganizationDomainCheck.count" do
        assert_raises(OrganizationDomain::DnsCheck::DeletedDomain) { stale.verify!(resolver: res) }
      end
      assert_empty res.queries
    end

    should "not record anything for a domain removed during the lookup" do
      res = FakeDnsResolver.new({ [@name, TXT] => [txt(@domain.txt_record_value)] })
      id = @domain.id
      actor = create(:user)
      res.define_singleton_method(:getresources) do |*args|
        OrganizationDomain.find(id).remove!(actor:)
        super(*args)
      end

      assert_no_difference "OrganizationDomainCheck.count" do
        assert_raises(OrganizationDomain::DnsCheck::DeletedDomain) { @domain.verify!(resolver: res) }
      end
      refute OrganizationDomain.exists?(id)
    end
  end

  context "default resolver" do
    should "open Resolv::DNS with system defaults, set the timeout and use absolute names" do
      fake = FakeDnsResolver.new
      fake.expects(:timeouts=).with(30)
      fake.expects(:close).at_least_once
      Resolv::DNS.expects(:new).with.returns(fake)

      check = @domain.verify!

      assert_equal "record_not_found", check.outcome
      assert_equal [[@name, TXT]], fake.queries
    end
  end
end
