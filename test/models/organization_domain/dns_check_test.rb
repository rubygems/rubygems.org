# frozen_string_literal: true

require "test_helper"
require "helpers/fake_dns_resolver"

class OrganizationDomain::DnsCheckTest < ActiveSupport::TestCase
  TXT = Resolv::DNS::Resource::IN::TXT
  NAME = "_rubygems-challenge.example.com"
  VALUE = "rubygems-verification=expected-token"

  def txt(*strings)
    TXT.new(*strings)
  end

  def lookup(answers = {})
    @resolver = FakeDnsResolver.new(answers)
    OrganizationDomain::DnsCheck.call(name: NAME, expected_value: VALUE, resolver: @resolver)
  end

  def assert_result(result, outcome, message)
    assert_equal outcome, result.outcome
    assert_equal message, result.message
  end

  context "matched" do
    should "return matched when a value equals the expected value" do
      assert_result lookup({ ["#{NAME}.", TXT] => [txt(VALUE)] }),
        "matched", "Found a matching TXT record at #{NAME}."
    end

    should "join split strings with no separator" do
      assert_equal "matched", lookup({ ["#{NAME}.", TXT] => [txt(VALUE[0, 10], VALUE[10..])] }).outcome
    end

    should "strip whitespace and accept any one of several values" do
      assert_equal "matched", lookup({ ["#{NAME}.", TXT] => [txt("other"), txt("  #{VALUE}\n")] }).outcome
    end

    should "query only the absolute name for TXT" do
      lookup({ ["#{NAME}.", TXT] => [txt(VALUE)] })

      assert_equal [["#{NAME}.", TXT]], @resolver.queries
    end
  end

  should "return record_not_found when there is no TXT record" do
    assert_result lookup, "record_not_found", "No TXT record found at #{NAME}."
  end

  context "record_mismatch" do
    should "return record_mismatch without including the values found" do
      result = lookup({ ["#{NAME}.", TXT] => [txt("rubygems-verification=SECRET-FOUND"), txt("other")] })

      assert_result result, "record_mismatch", "A TXT record exists at #{NAME} but its value does not match."
      refute_includes result.message, "SECRET-FOUND"
    end

    should "not accept a quoted value" do
      assert_equal "record_mismatch", lookup({ ["#{NAME}.", TXT] => [txt(%("#{VALUE}"))] }).outcome
    end
  end

  context "other_error" do
    should "return a timeout with the fixed message and not report it" do
      Rails.error.expects(:report).never

      assert_result lookup({ ["#{NAME}.", TXT] => Timeout::Error.new("execution expired") }),
        "other_error", "DNS lookup timed out after 30 seconds."
    end

    should "treat a Resolv timeout as a timeout" do
      assert_result lookup({ ["#{NAME}.", TXT] => Resolv::ResolvTimeout.new("x") }),
        "other_error", "DNS lookup timed out after 30 seconds."
    end

    should "cap the whole lookup with Timeout" do
      Timeout.expects(:timeout).with(OrganizationDomain::DnsCheck::TIMEOUT).raises(Timeout::Error)

      assert_result lookup, "other_error", "DNS lookup timed out after 30 seconds."
      assert_equal 30, OrganizationDomain::DnsCheck::TIMEOUT
    end

    should "return the class and message of any other exception and report it" do
      Rails.error.expects(:report).with { |e, opts| e.is_a?(SocketError) && opts == { handled: true } }

      assert_result lookup({ ["#{NAME}.", TXT] => SocketError.new("boom") }), "other_error", "SocketError: boom"
    end

    should "truncate long messages to the stored message limit" do
      result = lookup({ ["#{NAME}.", TXT] => RuntimeError.new("x" * 1000) })

      assert_equal OrganizationDomainCheck::MAX_MESSAGE_LENGTH, result.message.length
    end
  end

  should "not touch the database" do
    assert_no_queries { lookup({ ["#{NAME}.", TXT] => [txt(VALUE)] }) }
  end

  context "default resolver" do
    should "open Resolv::DNS with system defaults, set the timeout and use the absolute name" do
      fake = FakeDnsResolver.new
      fake.expects(:timeouts=).with(30)
      fake.expects(:close).at_least_once
      Resolv::DNS.expects(:new).with.returns(fake)

      result = OrganizationDomain::DnsCheck.call(name: NAME, expected_value: VALUE)

      assert_equal "record_not_found", result.outcome
      assert_equal [["#{NAME}.", TXT]], fake.queries
    end
  end
end
