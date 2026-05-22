# frozen_string_literal: true

require "test_helper"

class BlockedEmailDomainTest < ActiveSupport::TestCase
  context "validations" do
    setup { @record = build(:blocked_email_domain, domain: "mailinator.com") }

    subject { @record }

    should validate_presence_of(:domain)
    should validate_uniqueness_of(:domain).case_insensitive
    should_not allow_value("not_a_domain").for(:domain)
    should_not allow_value("missing-tld").for(:domain)
    should allow_value("mailinator.com").for(:domain)
    should allow_value("sub.mailinator.com").for(:domain)

    should "reject a public-suffix value to prevent locking out an entire ccTLD" do
      record = build(:blocked_email_domain, domain: "co.uk")

      refute_predicate record, :valid?
      assert_contains record.errors[:domain],
        "is a public suffix and cannot be used; specify a registrable domain"
    end

    should "reject a registry-managed multi-label suffix" do
      record = build(:blocked_email_domain, domain: "com.br")

      refute_predicate record, :valid?
    end

    should "accept a registrable name under a ccTLD" do
      record = build(:blocked_email_domain, domain: "shady.co.uk")

      assert_predicate record, :valid?
    end

    should "reject a protected consumer mail provider to defend against admin misclicks" do
      record = build(:blocked_email_domain, domain: "gmail.com")

      refute_predicate record, :valid?
      assert_contains record.errors[:domain],
        "is a major consumer mail provider and cannot be blocked"
    end

    should "reject a regional protected provider" do
      record = build(:blocked_email_domain, domain: "qq.com")

      refute_predicate record, :valid?
    end
  end

  context "#normalize_domain" do
    should "downcase and strip the domain before validation" do
      record = BlockedEmailDomain.create!(domain: "  Mailinator.COM  ")

      assert_equal "mailinator.com", record.domain
    end
  end

  context ".blocks?" do
    setup { create(:blocked_email_domain, domain: "mailinator.com") }

    should "match an exact domain" do
      assert BlockedEmailDomain.blocks?("user@mailinator.com")
    end

    should "match by suffix on a subdomain" do
      assert BlockedEmailDomain.blocks?("user@foo.mailinator.com")
      assert BlockedEmailDomain.blocks?("user@deep.sub.mailinator.com")
    end

    should "be case-insensitive" do
      assert BlockedEmailDomain.blocks?("USER@MAILINATOR.COM")
    end

    should "accept a bare domain without @" do
      assert BlockedEmailDomain.blocks?("mailinator.com")
      assert BlockedEmailDomain.blocks?("foo.mailinator.com")
    end

    should "not match unrelated domains" do
      refute BlockedEmailDomain.blocks?("user@gmail.com")
      refute BlockedEmailDomain.blocks?("user@mailinator-not.com")
    end

    should "yield to the allowlist when a parent domain is allowlisted" do
      create(:email_domain_allowlist, domain: "mailinator.com")

      refute BlockedEmailDomain.blocks?("user@mailinator.com")
      refute BlockedEmailDomain.blocks?("user@sub.mailinator.com")
    end

    should "return false for blank input" do
      refute BlockedEmailDomain.blocks?(nil)
      refute BlockedEmailDomain.blocks?("")
      refute BlockedEmailDomain.blocks?("user@")
    end
  end

  context ".match" do
    setup { @row = create(:blocked_email_domain, :upstream, domain: "mailinator.com") }

    should "return the matched row" do
      assert_equal @row, BlockedEmailDomain.match("user@mailinator.com")
    end

    should "return the matched row on a subdomain" do
      assert_equal @row, BlockedEmailDomain.match("user@inbox.mailinator.com")
    end

    should "return nil when allowlisted" do
      create(:email_domain_allowlist, domain: "mailinator.com")

      assert_nil BlockedEmailDomain.match("user@mailinator.com")
    end

    should "return nil for unrelated domains" do
      assert_nil BlockedEmailDomain.match("user@gmail.com")
    end

    should "prefer the most-specific match when multiple parents are blocked" do
      specific = create(:blocked_email_domain, domain: "sub.mailinator.com")

      assert_equal specific, BlockedEmailDomain.match("user@sub.mailinator.com"),
        "sub.mailinator.com should win over the broader mailinator.com when both are blocked"
    end
  end

  context "source enum" do
    should "default new records to manual so admin-created rows survive the upstream sync" do
      record = BlockedEmailDomain.create!(domain: "mailinator.com")

      assert_predicate record, :manual?
    end

    should "allow promoting between sources" do
      record = create(:blocked_email_domain, :upstream, domain: "guerrillamail.com")
      record.update!(source: :manual)

      assert_predicate record, :manual?
    end
  end
end
