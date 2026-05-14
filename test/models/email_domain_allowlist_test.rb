# frozen_string_literal: true

require "test_helper"

class EmailDomainAllowlistTest < ActiveSupport::TestCase
  context "validations" do
    setup { @record = build(:email_domain_allowlist, domain: "privaterelay.appleid.com") }

    subject { @record }

    should validate_presence_of(:domain)
    should validate_uniqueness_of(:domain).case_insensitive
    should_not allow_value("not_a_domain").for(:domain)
    should allow_value("privaterelay.appleid.com").for(:domain)
  end

  context ".allows?" do
    setup { create(:email_domain_allowlist, domain: "privaterelay.appleid.com") }

    should "match an exact domain" do
      assert EmailDomainAllowlist.allows?("user@privaterelay.appleid.com")
    end

    should "match by suffix on a subdomain" do
      assert EmailDomainAllowlist.allows?("user@x.privaterelay.appleid.com")
    end

    should "be case-insensitive" do
      assert EmailDomainAllowlist.allows?("USER@PRIVATERELAY.APPLEID.COM")
    end

    should "not match unrelated domains" do
      refute EmailDomainAllowlist.allows?("user@example.com")
    end

    should "return false for blank input" do
      refute EmailDomainAllowlist.allows?(nil)
      refute EmailDomainAllowlist.allows?("")
    end
  end
end
