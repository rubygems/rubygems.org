# frozen_string_literal: true

require "test_helper"
require "helpers/fake_dns_resolver"

class OrganizationDomainVerifyTest < ActiveSupport::TestCase
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
    assert_equal message, check.message if message
    domain.reload

    assert_nil domain.verified_at
    assert_equal "failure", domain.last_check_result
    assert_equal check.checked_at.to_i, domain.last_checked_at.to_i
    assert_nil domain.check_queued_at
  end

  context "recording" do
    should "record a success, verify the domain and clear check_queued_at" do
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

    should "record each failure outcome DnsCheck returns" do
      assert_failure verify, :record_not_found, message: "No TXT record found at _rubygems-challenge.example.com."
      assert_failure verify({ [@name, TXT] => [txt("wrong")] }), :record_mismatch
      assert_failure verify({ [@name, TXT] => SocketError.new("boom") }), :other_error, message: "SocketError: boom"
    end

    should "match only this domain's own value" do
      check = verify({ [@name, TXT] => [txt(create(:organization_domain, domain: "example.com").txt_record_value)] })

      assert_failure check, :record_mismatch
    end

    should "record a failure when another organization already verified the domain" do
      other = create(:organization_domain, :verified, domain: "example.com")
      other_verified_at = other.reload.verified_at

      assert_no_difference -> { other.reload.checks.count } do
        assert_difference -> { @domain.checks.count }, 1 do
          check = verify({ [@name, TXT] => [txt(@domain.txt_record_value)] })

          assert_failure check, :other_error, message: "Another organization has already verified this domain."
        end
      end
      assert_equal other_verified_at, other.reload.verified_at
    end

    should "un-verify a previously verified domain on a later failure" do
      assert_predicate verify({ [@name, TXT] => [txt(@domain.txt_record_value)] }), :success?

      assert_failure verify, :record_not_found
      assert_equal %w[failure success], @domain.checks.pluck(:result)
    end

    should "not accept the token of a deleted and re-added domain" do
      old_value = @domain.txt_record_value
      @domain.destroy_with_audit!(actor: create(:user))
      fresh = create(:organization_domain, domain: "example.com")

      assert_failure verify({ [@name, TXT] => [txt(old_value)] }, domain: fresh), :record_mismatch, domain: fresh
    end
  end

  context "guards" do
    should "refuse a new record without a DNS request" do
      domain = build(:organization_domain, domain: "example.com")
      OrganizationDomain::DnsCheck.expects(:call).never

      assert_raises(OrganizationDomain::InvalidDomain) { domain.verify! }
    end

    should "refuse a record with unsaved changes without a DNS request or a check" do
      @domain.verified_at = Time.current
      OrganizationDomain::DnsCheck.expects(:call).never

      assert_no_difference "OrganizationDomainCheck.count" do
        assert_raises(OrganizationDomain::InvalidDomain) { @domain.verify! }
      end
    end

    should "refuse an invalid stored domain without a DNS request or a check" do
      OrganizationDomain::Name.stubs(:valid?).returns(false)
      OrganizationDomain::DnsCheck.expects(:call).never

      assert_no_difference "OrganizationDomainCheck.count" do
        assert_raises(OrganizationDomain::InvalidDomain) { @domain.verify! }
      end
    end

    should "refuse a destroyed domain without a DNS request or a check" do
      @domain.destroy_with_audit!(actor: create(:user))
      OrganizationDomain::DnsCheck.expects(:call).never

      assert_no_difference "OrganizationDomainCheck.count" do
        assert_raises(OrganizationDomain::DeletedDomain) { @domain.verify! }
      end
    end

    should "refuse a domain deleted elsewhere without a DNS request or a check" do
      stale = OrganizationDomain.find(@domain.id)
      @domain.destroy_with_audit!(actor: create(:user))
      OrganizationDomain::DnsCheck.expects(:call).never

      assert_no_difference "OrganizationDomainCheck.count" do
        assert_raises(OrganizationDomain::DeletedDomain) { stale.verify! }
      end
    end

    should "not record anything for a domain deleted during the lookup" do
      res = FakeDnsResolver.new({ [@name, TXT] => [txt(@domain.txt_record_value)] })
      id = @domain.id
      actor = create(:user)
      res.define_singleton_method(:getresources) do |*args|
        OrganizationDomain.find(id).destroy_with_audit!(actor:)
        super(*args)
      end

      assert_no_difference "OrganizationDomainCheck.count" do
        assert_raises(OrganizationDomain::DeletedDomain) { @domain.verify!(resolver: res) }
      end
      refute OrganizationDomain.exists?(id)
    end

    should "pass DnsCheck only the record name and expected value" do
      OrganizationDomain::DnsCheck.expects(:call)
        .with(name: @domain.txt_record_name, expected_value: @domain.txt_record_value, resolver: nil)
        .returns(OrganizationDomain::DnsCheck::Result.new(outcome: "record_not_found", message: "none"))

      assert_failure @domain.verify!, :record_not_found, message: "none"
    end
  end
end
