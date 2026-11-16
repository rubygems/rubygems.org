# frozen_string_literal: true

require "test_helper"
require "helpers/fake_dns_helpers"

class Organizations::DomainsTest < ActionDispatch::IntegrationTest
  include FakeDnsHelpers

  setup do
    @owner = create(:user)
    @organization = create(:organization, owners: [@owner], handle: "arrakis", name: "Arrakis")
    @resolver = stub_dns(FakeDnsResolver.new)
  end

  def sign_in(user)
    post session_path(session: { who: user.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })
  end

  def testid(id, **)
    assert_select "[data-testid=?]", id, **
  end

  def state_counts
    [OrganizationDomain.count, OrganizationDomainCheck.count, OrganizationDomain.where.not(deleted_at: nil).count]
  end

  def assert_denied(expected)
    assert_includes expected, response.status
    assert_equal @counts, state_counts
    assert_empty @resolver.queries
  end

  def attempt_all(expected)
    post organization_domains_path(@organization), params: { organization_domain: { domain: "new.example.com" } }

    assert_denied expected
    post verify_organization_domain_path(@organization, @domain)

    assert_denied expected
    delete organization_domain_path(@organization, @domain)

    assert_denied expected
  end

  context "settings page" do
    should "show the domains card and add form to an owner" do
      sign_in @owner
      get edit_organization_path(@organization)

      assert_response :success
      testid "organization-domains"
      testid "organization-domain-form"
      testid "organization-domain-input"
      testid "organization-domain", count: 0
    end

    should "show each domain with its TXT record, status and buttons" do
      pending = create(:organization_domain, organization: @organization, domain: "pending.example.com")
      create(:organization_domain, :verified, organization: @organization, domain: "ok.example.com")
      create(:organization_domain, :deleted, organization: @organization, domain: "gone.example.com")
      sign_in @owner
      get edit_organization_path(@organization)

      testid "organization-domain", count: 2
      assert_select "[data-testid=?][data-domain=?]", "organization-domain", "pending.example.com" do
        testid "organization-domain-status", text: /pending/i

        assert_select "[data-testid=?] input[value=?]", "organization-domain-txt-name", "_rubygems-challenge.pending.example.com"
        assert_select "[data-testid=?] input[value=?]", "organization-domain-txt-value", pending.txt_record_value
        testid "organization-domain-verify"
        testid "organization-domain-retry", count: 0
        testid "organization-domain-remove"
      end
      assert_select "[data-testid=?][data-domain=?]", "organization-domain", "ok.example.com" do
        testid "organization-domain-status", text: /verified/i
      end
      refute_match(/gone\.example\.com/, response.body)
    end

    should "show readable button labels" do
      create(:organization_domain, organization: @organization, domain: "pending.example.com")
      failed = create(:organization_domain, organization: @organization, domain: "bad.example.com", last_check_result: "failure")
      create(:organization_domain_check, :failure, organization_domain: failed)
      create(:organization_domain, :verified, organization: @organization, domain: "ok.example.com")
      sign_in @owner
      get edit_organization_path(@organization)

      assert_select "[data-testid=?][data-domain=?] [data-testid=?]", "organization-domain", "pending.example.com", "organization-domain-verify",
text: "Verify"
      assert_select "[data-testid=?][data-domain=?] [data-testid=?]", "organization-domain", "bad.example.com", "organization-domain-retry",
text: "Retry"
      assert_select "[data-testid=?][data-domain=?] [data-testid=?]", "organization-domain", "ok.example.com", "organization-domain-verify",
text: "Verify again"
      assert_select "[data-testid=?]", "organization-domain-remove", text: "Remove", count: 3
    end

    should "show the TXT record for a verified domain too" do
      verified = create(:organization_domain, :verified, organization: @organization, domain: "ok.example.com")
      sign_in @owner
      get edit_organization_path(@organization)

      assert_select "[data-testid=?] input[value=?]", "organization-domain-txt-name", verified.txt_record_name
      assert_select "[data-testid=?] input[value=?]", "organization-domain-txt-value", verified.txt_record_value
    end

    should "load the latest checks in a single query" do
      domain = create(:organization_domain, organization: @organization, domain: "bad.example.com")
      3.times { |i| create(:organization_domain_check, :failure, organization_domain: domain, checked_at: (i + 1).hours.ago) }
      sign_in @owner
      queries = []
      callback = lambda { |*, payload|
        queries << payload[:sql] if payload[:sql].start_with?("SELECT") && payload[:sql].include?("FROM \"organization_domain_checks\"")
      }
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { get edit_organization_path(@organization) }

      assert_response :success
      assert_equal 1, queries.size
      assert_match(/DISTINCT ON/, queries.first)
    end

    should "show a Retry button and the failure details after a failed check" do
      domain = create(:organization_domain, organization: @organization, domain: "bad.example.com",
        last_check_result: "failure")
      create(:organization_domain_check, :failure, organization_domain: domain, error_code: "record_not_found",
        error_message: "No TXT records at _rubygems-challenge.bad.example.com.")
      sign_in @owner
      get edit_organization_path(@organization)

      testid "organization-domain-status", text: /failed/i
      testid "organization-domain-retry"
      testid "organization-domain-verify", count: 0
      testid "organization-domain-failure"
      testid "organization-domain-failure-detail", text: /_rubygems-challenge\.bad\.example\.com/
      testid "organization-domain-failure-message", text: /No TXT records/
      testid "organization-domain-checked-at"
    end

    %w[token_mismatch value_mismatch value_quoted].each do |code|
      should "only say the DNS value does not match for #{code}, without showing what was found" do
        domain = create(:organization_domain, organization: @organization, domain: "bad.example.com",
          last_check_result: "failure")
        create(:organization_domain_check, :failure, organization_domain: domain, error_code: code,
          error_message: %(TXT values seen: ["rubygems-verification=FOUND-VALUE-abc"]))
        sign_in @owner
        get edit_organization_path(@organization)

        testid "organization-domain-failure" do
          assert_select "h3", text: "The DNS value doesn't match"
        end
        testid "organization-domain-failure-detail",
          text: "The TXT record at _rubygems-challenge.bad.example.com doesn't match the value shown above."
        testid "organization-domain-failure-message", count: 0
        testid "organization-domain-retry"
        testid "organization-domain-checked-at"

        refute_includes response.body, "FOUND-VALUE-abc"
        refute_match(/values seen|quotation marks|token doesn't match|what we saw/i, response.body)
      end
    end
  end

  context "add domain" do
    should "create the domain and show the generated TXT record" do
      sign_in @owner

      assert_difference -> { @organization.domains.count }, 1 do
        post organization_domains_path(@organization), params: { organization_domain: { domain: " Example.COM " } }
      end
      assert_redirected_to edit_organization_path(@organization)
      follow_redirect!

      domain = @organization.domains.sole

      assert_equal "example.com", domain.domain
      assert_select "[data-testid=?] input[value=?]", "organization-domain-txt-name", "_rubygems-challenge.example.com"
      assert_select "[data-testid=?] input[value=?]", "organization-domain-txt-value", domain.txt_record_value
      assert_empty @resolver.queries
    end

    should "ignore a posted token" do
      sign_in @owner
      post organization_domains_path(@organization), params: { organization_domain: { domain: "example.com", token: "evil" } }
      domain = @organization.domains.sole

      refute_equal "evil", domain.token
    end

    should "remove then re-add generates a new value and says the old record must be replaced" do
      sign_in @owner
      post organization_domains_path(@organization), params: { organization_domain: { domain: "example.com" } }
      old = @organization.domains.sole
      delete organization_domain_path(@organization, old)
      post organization_domains_path(@organization), params: { organization_domain: { domain: "example.com" } }
      follow_redirect!

      fresh = @organization.domains.sole

      refute_equal old.token, fresh.token
      assert_select "[data-testid=?] input[value=?]", "organization-domain-txt-value", fresh.txt_record_value
      assert_select "[data-testid=?] input[value=?]", "organization-domain-txt-value", old.txt_record_value, count: 0
      testid "organization-domain-readded-notice"
    end

    format_message = "Domain is invalid. The domain is expected in an example.com or docs.example.com format."
    ["https://example.com/path", "exa_mple.com", "user@example.com", "*.example.com", "example.com:443",
     "exämple.com", "127.0.0.1", "co.uk", "example.com.", "-bad_..com"].each do |input|
      should "reject #{input.inspect}, keep the input and look up nothing" do
        sign_in @owner

        assert_no_difference -> { OrganizationDomain.count } do
          post organization_domains_path(@organization), params: { organization_domain: { domain: input } }
        end
        assert_response :unprocessable_content
        assert_select "[data-testid=?][value=?]", "organization-domain-input", input
        testid "organization-domain-errors" do
          assert_select "li", count: 1, text: format_message
        end

        assert_empty @resolver.queries
      end
    end

    should "reject a duplicate of an active domain" do
      create(:organization_domain, organization: @organization, domain: "example.com")
      sign_in @owner

      assert_no_difference -> { OrganizationDomain.count } do
        post organization_domains_path(@organization), params: { organization_domain: { domain: "EXAMPLE.com" } }
      end
      assert_response :unprocessable_content
    end
  end

  context "verify and retry" do
    setup do
      @domain = create(:organization_domain, organization: @organization, domain: "example.com")
      sign_in @owner
    end

    should "walk from a failed check to a verified domain" do
      stub_dns(FakeDnsResolver.for_domain("example.com"))
      post verify_organization_domain_path(@organization, @domain)

      assert_redirected_to edit_organization_path(@organization)
      follow_redirect!

      testid "organization-domain-failure"
      testid "organization-domain-failure-detail", text: /_rubygems-challenge\.example\.com/
      testid "organization-domain-failure-message"
      testid "organization-domain-retry"

      stub_dns(FakeDnsResolver.for_domain("example.com", value: @domain.txt_record_value))
      post verify_organization_domain_path(@organization, @domain)
      follow_redirect!

      assert_predicate @domain.reload, :verified?
      testid "organization-domain-status", text: /verified/i
      testid "organization-domain-failure", count: 0

      assert_equal %w[success failure], @domain.checks.pluck(:result)
    end

    should "let the owner re-check a verified domain, and a failing re-check un-verifies it" do
      stub_dns(FakeDnsResolver.for_domain("example.com", value: @domain.txt_record_value))
      post verify_organization_domain_path(@organization, @domain)

      assert_predicate @domain.reload, :verified?

      get edit_organization_path(@organization)

      testid "organization-domain-verify", text: "Verify again"

      stub_dns(FakeDnsResolver.for_domain("example.com"))
      assert_difference -> { @domain.checks.count }, 1 do
        post verify_organization_domain_path(@organization, @domain)
      end
      follow_redirect!

      refute_predicate @domain.reload, :verified?
      testid "organization-domain-retry"
    end

    should "404 for a removed domain and record no check" do
      @domain.remove!

      assert_no_difference -> { OrganizationDomainCheck.count } do
        post verify_organization_domain_path(@organization, @domain)
      end
      assert_response :not_found
      assert_empty @resolver.queries
    end

    should "handle a DnsCheck error without a 500" do
      OrganizationDomain.any_instance.stubs(:verify!).raises(OrganizationDomain::DnsCheck::DeletedDomain)
      post verify_organization_domain_path(@organization, @domain)

      assert_redirected_to edit_organization_path(@organization)
    end
  end

  context "remove" do
    should "soft delete the domain" do
      domain = create(:organization_domain, organization: @organization, domain: "example.com")
      sign_in @owner
      delete organization_domain_path(@organization, domain)

      assert_redirected_to edit_organization_path(@organization)
      refute_nil domain.reload.deleted_at
      assert_empty @organization.domains
    end

    should "404 for an already removed domain" do
      domain = create(:organization_domain, :deleted, organization: @organization, domain: "example.com")
      sign_in @owner
      delete organization_domain_path(@organization, domain)

      assert_response :not_found
    end
  end

  context "denied access" do
    setup do
      @domain = create(:organization_domain, organization: @organization, domain: "example.com")
      other_owner = create(:user)
      create(:organization, owners: [other_owner])
      @actors = {
        admin: create(:user),
        maintainer: create(:user),
        non_member: create(:user),
        other_org_owner: other_owner
      }
      create(:membership, user: @actors[:admin], organization: @organization, role: :admin, confirmed_at: Time.zone.now)
      create(:membership, user: @actors[:maintainer], organization: @organization, role: :maintainer, confirmed_at: Time.zone.now)
      @counts = state_counts
    end

    %i[admin maintainer non_member other_org_owner].each do |role|
      should "deny #{role} every action" do
        sign_in @actors[role]
        attempt_all [403, 404]

        refute_predicate @domain.reload, :verified?
        assert_nil @domain.deleted_at
      end
    end

    should "deny a signed-out user every action" do
      attempt_all [302]

      assert_redirected_to sign_in_path
    end

    should "deny an admin the settings page" do
      sign_in @actors[:admin]
      get edit_organization_path(@organization)

      assert_response :forbidden
    end
  end

  context "cross-organization access" do
    should "404 for another organization's domain id under the owner's own organization path" do
      victim = create(:organization_domain, organization: create(:organization), domain: "victim.example.com")
      resolver = stub_dns(FakeDnsResolver.for_domain("victim.example.com", value: victim.txt_record_value))
      sign_in @owner
      counts = state_counts

      post verify_organization_domain_path(@organization, victim)

      assert_response :not_found
      delete organization_domain_path(@organization, victim)

      assert_response :not_found
      assert_equal counts, state_counts
      assert_empty resolver.queries
      assert_nil victim.reload.deleted_at
      refute_predicate victim, :verified?
    end
  end

  context "adding a domain concurrently" do
    should "re-render with a taken error instead of a 500 when the add race is lost" do
      create(:organization_domain, organization: @organization, domain: "example.com")
      ActiveRecord::Validations::UniquenessValidator.any_instance.stubs(:validate_each)
      sign_in @owner

      assert_no_difference "OrganizationDomain.count" do
        post organization_domains_path(@organization), params: { organization_domain: { domain: "example.com" } }
      end

      assert_response :unprocessable_content
      testid "organization-domain-input"
    end
  end

  context "error code locale keys" do
    should "exist for every error code and group" do
      OrganizationDomainCheck.error_codes.each_key do |code|
        assert I18n.exists?("organizations.domains.error_codes.#{code}"), "missing code key #{code}"
      end
      OrganizationDomainCheck::ERROR_GROUPS.each_key do |group|
        assert I18n.exists?("organizations.domains.error_groups.#{group}.heading"), "missing group heading #{group}"
        assert I18n.exists?("organizations.domains.error_groups.#{group}.hint"), "missing group hint #{group}"
      end
    end

    should "keep button labels as strings in every locale file" do
      buttons = %w[verify recheck retry remove]
      results = %w[verified failed unavailable]
      I18n.available_locales.each do |locale|
        buttons.each do |key|
          assert_kind_of String, I18n.t("organizations.domains.#{key}", locale:), "#{locale} #{key}"
        end
        results.each do |key|
          assert_kind_of String, I18n.t("organizations.domains.verify_result.#{key}", locale:, domain: "example.com"), "#{locale} #{key}"
        end
      end
    end

    should "render for every code on the settings page" do
      sign_in @owner
      OrganizationDomainCheck.error_codes.each_key do |code|
        domain = create(:organization_domain, organization: @organization, last_check_result: "failure")
        create(:organization_domain_check, :failure, organization_domain: domain, error_code: code)
      end
      get edit_organization_path(@organization)

      assert_response :success
      testid "organization-domain-failure", count: OrganizationDomainCheck.error_codes.size

      refute_match(/translation missing|translation_missing/i, response.body)
    end
  end
end
