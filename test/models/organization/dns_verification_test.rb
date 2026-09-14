# frozen_string_literal: true

require "test_helper"

class Organization::DnsVerificationTest < ActiveSupport::TestCase
  setup do
    @organization = create(:organization, handle: "arrakis", name: "Arrakis")
  end

  context "claiming a domain" do
    should "issue a verification token" do
      @organization.update!(domain: "arrakis.example.com")

      assert_predicate @organization.dns_verification_token, :present?
    end

    should "issue a distinct token to each organization claiming the same domain" do
      other = create(:organization, handle: "caladan", name: "Caladan", domain: "arrakis.example.com")
      @organization.update!(domain: "arrakis.example.com")

      refute_equal other.dns_verification_token, @organization.dns_verification_token
    end

    should "start out unverified" do
      @organization.update!(domain: "arrakis.example.com")

      refute_predicate @organization, :dns_verified?
      assert_nil @organization.dns_last_checked_at
    end

    should "normalize case and surrounding whitespace" do
      @organization.update!(domain: "  ARRAKIS.EXAMPLE.com ")

      assert_equal "arrakis.example.com", @organization.domain
    end

    should "treat a blank domain as no claim and drop the token" do
      @organization.update!(domain: "arrakis.example.com")

      @organization.update!(domain: "")

      assert_nil @organization.domain
      assert_nil @organization.dns_verification_token
    end

    should "reject a domain that isn't a domain name" do
      @organization.domain = "not a domain"

      refute_predicate @organization, :valid?
      assert_equal ["must be a domain name, like example.com"], @organization.errors[:domain]
    end

    should "reject a URL rather than silently storing it" do
      @organization.domain = "https://arrakis.example.com/path"

      refute_predicate @organization, :valid?
    end

    should "reject a public suffix that nobody can register" do
      @organization.domain = "co.uk"

      refute_predicate @organization, :valid?
      assert_equal ["is a public suffix and cannot be used; specify a registrable domain"], @organization.errors[:domain]
    end

    # PublicSuffix's wildcard default rule would otherwise accept any invented
    # TLD as a registrable domain.
    should "reject a top-level domain that does not exist" do
      @organization.domain = "arrakis.zzzznotatld"

      refute_predicate @organization, :valid?
      assert_equal ["does not use a known top-level domain"], @organization.errors[:domain]
    end

    should "reject the RFC 2606 and private-use top-level domains" do
      %w[arrakis.test arrakis.example arrakis.invalid arrakis.localhost arrakis.internal arrakis.local].each do |domain|
        @organization.domain = domain

        refute_predicate @organization, :valid?, "expected #{domain} to be rejected"
      end
    end

    should "allow a subdomain" do
      @organization.domain = "gems.arrakis.example.com"

      assert_predicate @organization, :valid?
    end
  end

  context "changing a verified domain" do
    setup do
      @organization.update!(domain: "arrakis.example.com")
      @organization.dns_verification_succeeded!
    end

    # Without this an organization could verify a domain it controls and then
    # repoint `domain` at a domain it does not, carrying the verification over.
    should "revoke the verification" do
      @organization.update!(domain: "caladan.example.com")

      refute_predicate @organization, :dns_verified?
      assert_nil @organization.dns_last_checked_at
    end

    should "issue a new token" do
      previous_token = @organization.dns_verification_token

      @organization.update!(domain: "caladan.example.com")

      refute_equal previous_token, @organization.dns_verification_token
    end

    should "keep the verification when the domain is re-saved unchanged" do
      @organization.update!(domain: "arrakis.example.com", name: "Arrakis Inc")

      assert_predicate @organization, :dns_verified?
    end

    should "keep the verification when the domain only differs by case or whitespace" do
      @organization.update!(domain: " Arrakis.EXAMPLE.COM ")

      assert_predicate @organization, :dns_verified?
    end

    should "revoke the verification when the domain is cleared" do
      @organization.update!(domain: nil)

      refute_predicate @organization, :dns_verified?
      assert_nil @organization.dns_verification_token
    end
  end

  context "the verification validity window" do
    setup do
      @organization.update!(domain: "arrakis.example.com")
      @organization.dns_verification_succeeded!
    end

    should "count a recent success as verified" do
      assert_predicate @organization, :dns_verified?
    end

    # Verification can never outlive the job that maintains it: if the sweep
    # stops running, verifications lapse instead of persisting indefinitely.
    should "lapse once no check has succeeded inside the validity window" do
      @organization.update_columns(dns_verified_at: (Organization::DnsVerification::VALIDITY + 1.day).ago)

      refute_predicate @organization.reload, :dns_verified?
    end

    should "still count as verified just inside the validity window" do
      @organization.update_columns(dns_verified_at: (Organization::DnsVerification::VALIDITY - 1.hour).ago)

      assert_predicate @organization.reload, :dns_verified?
    end

    should "keep the lapsed timestamp as the record of the last success" do
      lapsed_at = (Organization::DnsVerification::VALIDITY + 1.day).ago
      @organization.update_columns(dns_verified_at: lapsed_at)

      assert_in_delta lapsed_at, @organization.reload.dns_verified_at, 1.second
    end

    should "exclude a lapsed organization from the dns_verified scope" do
      @organization.update_columns(dns_verified_at: (Organization::DnsVerification::VALIDITY + 1.day).ago)

      refute_includes Organization.dns_verified, @organization
    end

    should "include a recently verified organization in the dns_verified scope" do
      assert_includes Organization.dns_verified, @organization
    end

    # A domain is re-checked far more often than the window is long, so a
    # verification only lapses if checks have genuinely stopped succeeding.
    should "re-check a domain well inside the validity window" do
      assert_operator Organization::DnsVerification::CHECK_INTERVAL, :<, Organization::DnsVerification::VALIDITY
    end
  end

  context "#should_verify_dns?" do
    should "be false without a claimed domain" do
      refute_predicate @organization, :should_verify_dns?
    end

    should "be true for a domain that has never been checked" do
      @organization.update!(domain: "arrakis.example.com")

      assert_predicate @organization, :should_verify_dns?
    end

    should "be false for a domain checked within the check interval" do
      @organization.update!(domain: "arrakis.example.com")
      @organization.dns_verification_succeeded!

      refute_predicate @organization, :should_verify_dns?
    end

    should "be true for a domain checked before the check interval" do
      @organization.update!(domain: "arrakis.example.com")
      @organization.update!(dns_last_checked_at: (Organization::DnsVerification::CHECK_INTERVAL + 1.minute).ago)

      assert_predicate @organization, :should_verify_dns?
    end
  end

  context "#dns_txt_record_name" do
    should "be the domain apex" do
      @organization.update!(domain: "arrakis.example.com")

      assert_equal "arrakis.example.com", @organization.dns_txt_record_name
    end
  end

  context "#dns_txt_record_value" do
    should "be the token behind the rubygems-verification prefix" do
      @organization.update!(domain: "arrakis.example.com")

      assert_equal "rubygems-verification=#{@organization.dns_verification_token}", @organization.dns_txt_record_value
    end

    should "be nil without a claimed domain" do
      assert_nil @organization.dns_txt_record_value
    end
  end

  context ".pending_dns_verification" do
    should "include an organization that has never been checked" do
      @organization.update!(domain: "arrakis.example.com")

      assert_includes Organization.pending_dns_verification, @organization
    end

    should "exclude an organization without a domain" do
      refute_includes Organization.pending_dns_verification, @organization
    end

    should "exclude an organization checked within the check interval" do
      @organization.update!(domain: "arrakis.example.com")
      @organization.dns_verification_succeeded!

      refute_includes Organization.pending_dns_verification, @organization
    end

    should "include an organization checked before the check interval" do
      @organization.update!(domain: "arrakis.example.com")
      @organization.update!(dns_last_checked_at: (Organization::DnsVerification::CHECK_INTERVAL + 1.minute).ago)

      assert_includes Organization.pending_dns_verification, @organization
    end
  end

  context "recording check results" do
    setup { @organization.update!(domain: "arrakis.example.com") }

    should "record success" do
      @organization.dns_verification_succeeded!

      assert_predicate @organization, :dns_verified?
      assert_not_nil @organization.dns_last_checked_at
    end

    should "clear the verification on failure" do
      @organization.dns_verification_succeeded!

      @organization.dns_verification_failed!

      refute_predicate @organization, :dns_verified?
      assert_not_nil @organization.dns_last_checked_at
    end

    should "leave the verification alone when the check is inconclusive" do
      @organization.dns_verification_succeeded!
      verified_at = @organization.dns_verified_at

      @organization.dns_verification_inconclusive!

      assert_equal verified_at, @organization.dns_verified_at
    end
  end
end
