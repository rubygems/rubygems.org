# frozen_string_literal: true

require "test_helper"
require "helpers/fake_dns_helpers"

class Organizations::DomainsTest < ActionDispatch::IntegrationTest
  include FakeDnsHelpers

  BUTTON_KEYS = %w[verify recheck retry remove].freeze

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
    [OrganizationDomain.count, OrganizationDomainCheck.count, Events::OrganizationEvent.count]
  end

  def assert_denied(expected)
    assert_includes expected, response.status
    assert_equal @counts, state_counts
    assert_empty @resolver.queries
    assert_no_enqueued_jobs only: OrganizationDomainVerificationJob
    assert_nil @domain.reload.check_queued_at
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

    should "show a Retry button and the failure text after a failed check" do
      domain = create(:organization_domain, organization: @organization, domain: "bad.example.com",
        last_check_result: "failure")
      create(:organization_domain_check, :failure, organization_domain: domain)
      sign_in @owner
      get edit_organization_path(@organization)

      testid "organization-domain-status", text: /failed/i
      testid "organization-domain-retry"
      testid "organization-domain-verify", count: 0
      testid "organization-domain-failure"
      testid "organization-domain-checked-at"
    end

    {
      "record_not_found" => "We couldn't find a TXT record at _rubygems-challenge.bad.example.com.",
      "record_mismatch" => "The TXT record at _rubygems-challenge.bad.example.com doesn't match the value shown below.",
      "other_error" => "We couldn't complete the DNS lookup for _rubygems-challenge.bad.example.com. Please retry later."
    }.each do |outcome, text|
      should "show the localized message for #{outcome}, the retry hint and never the stored message" do
        domain = create(:organization_domain, organization: @organization, domain: "bad.example.com",
          last_check_result: "failure")
        create(:organization_domain_check, :failure, organization_domain: domain, outcome:,
          message: "STORED-ADMIN-MESSAGE rubygems-verification=FOUND-VALUE-abc")
        sign_in @owner
        get edit_organization_path(@organization)

        testid "organization-domain-failure" do
          assert_select "[data-testid=?]", "organization-domain-failure-detail", text: text
          assert_select "p", text: "Retry runs in the background; revisit this page later. DNS changes can take a while to propagate."
        end
        testid "organization-domain-retry"
        testid "organization-domain-checked-at"

        refute_includes response.body, "STORED-ADMIN-MESSAGE"
        refute_includes response.body, "FOUND-VALUE-abc"
      end
    end

    should "show the Checking state while a check is queued, hiding Verify and Retry but not Remove" do
      create(:organization_domain, organization: @organization, domain: "wait.example.com", check_queued_at: Time.current)
      failed = create(:organization_domain, organization: @organization, domain: "bad.example.com",
        last_check_result: "failure", check_queued_at: Time.current)
      create(:organization_domain_check, :failure, organization_domain: failed)
      sign_in @owner
      get edit_organization_path(@organization)

      testid "organization-domain", count: 2
      testid "organization-domain-status", text: "Checking", count: 2
      testid "organization-domain-checking", count: 2,
        text: "Verification is running in the background. Revisit this page later to see the result. DNS changes can take a while to propagate."
      testid "organization-domain-verify", count: 0
      testid "organization-domain-retry", count: 0
      testid "organization-domain-failure", count: 0
      testid "organization-domain-remove", count: 2
    end

    should "show a failed check above the domain it belongs to" do
      domain = create(:organization_domain, organization: @organization, domain: "bad.example.com",
        last_check_result: "failure")
      create(:organization_domain_check, :failure, organization_domain: domain)
      sign_in @owner
      get edit_organization_path(@organization)

      row = css_select("[data-domain=\"bad.example.com\"]").first.to_html
      failure_at = row.index(%(data-testid="organization-domain-failure"))
      domain_at = row.index("bad.example.com</span>")
      txt_at = row.index(%(data-testid="organization-domain-txt-name"))

      assert failure_at, "failure box missing"
      assert_operator failure_at, :<, domain_at, "failure box should come before the domain name"
      assert_operator domain_at, :<, txt_at, "domain name should come before the TXT record"
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

    should "record one added event with the owner as actor" do
      sign_in @owner

      assert_difference -> { @organization.events.where(tag: Events::OrganizationEvent::DOMAIN_ADDED).count }, 1 do
        post organization_domains_path(@organization), params: { organization_domain: { domain: "Example.com" } }
      end
      additional = @organization.events.where(tag: Events::OrganizationEvent::DOMAIN_ADDED).sole.additional

      assert_equal "example.com", additional.domain
      assert_equal @owner.to_gid, additional.actor_gid
    end

    should "ignore a posted token" do
      sign_in @owner
      post organization_domains_path(@organization), params: { organization_domain: { domain: "example.com", token: "evil" } }
      domain = @organization.domains.sole

      refute_equal "evil", domain.token
    end

    should "remove then re-add generates a new value" do
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

    should "enqueue exactly one job, mark the domain as checking and show the background notice" do
      assert_enqueued_jobs 1, only: OrganizationDomainVerificationJob do
        post verify_organization_domain_path(@organization, @domain)
      end

      assert_enqueued_with(job: OrganizationDomainVerificationJob, args: [@domain.id])
      assert_redirected_to edit_organization_path(@organization)
      refute_nil @domain.reload.check_queued_at
      assert_empty @resolver.queries
      assert_equal 0, OrganizationDomainCheck.count
      follow_redirect!

      assert_includes response.body,
        "We&#39;re verifying example.com in the background. Revisit this page later to see the result. DNS changes can take a while to propagate."
      testid "organization-domain-status", text: "Checking"
      testid "organization-domain-verify", count: 0
    end

    should "not enqueue a duplicate on a second click while one is queued" do
      assert_enqueued_jobs 1, only: OrganizationDomainVerificationJob do
        post verify_organization_domain_path(@organization, @domain)
        post verify_organization_domain_path(@organization, @domain)
      end

      assert_redirected_to edit_organization_path(@organization)
    end

    should "show Verify and allow a new enqueue when check_queued_at is stale" do
      @domain.update!(check_queued_at: Time.current)
      travel 11.minutes do
        get edit_organization_path(@organization)

        testid "organization-domain-status", text: "Pending"
        testid "organization-domain-verify"
        testid "organization-domain-checking", count: 0

        assert_enqueued_jobs 1, only: OrganizationDomainVerificationJob do
          post verify_organization_domain_path(@organization, @domain)
        end
        assert_operator @domain.reload.check_queued_at, :>, 1.minute.ago
      end
    end

    should "roll back check_queued_at and tell the owner when the enqueue is aborted" do
      OrganizationDomainVerificationJob.stubs(:perform_later).returns(false)
      post verify_organization_domain_path(@organization, @domain)

      assert_redirected_to edit_organization_path(@organization)
      assert_nil @domain.reload.check_queued_at
      assert_equal "We couldn't start the verification for example.com. Please try again.", flash[:alert]
    end

    should "walk from a failed check to a verified domain through the job" do
      stub_dns(FakeDnsResolver.for_domain("example.com"))
      perform_enqueued_jobs do
        post verify_organization_domain_path(@organization, @domain)
      end

      assert_nil @domain.reload.check_queued_at
      get edit_organization_path(@organization)

      testid "organization-domain-failure"
      testid "organization-domain-retry"

      stub_dns(FakeDnsResolver.for_domain("example.com", value: @domain.txt_record_value))
      perform_enqueued_jobs do
        post verify_organization_domain_path(@organization, @domain)
      end
      get edit_organization_path(@organization)

      assert_predicate @domain.reload, :verified?
      testid "organization-domain-status", text: /verified/i
      testid "organization-domain-failure", count: 0

      assert_equal %w[success failure], @domain.checks.pluck(:result)
    end

    should "let the owner re-check a verified domain, and a failing re-check un-verifies it" do
      verified = create(:organization_domain, :verified, organization: @organization, domain: "ok.example.com")
      get edit_organization_path(@organization)

      assert_select "[data-domain=?] [data-testid=?]", "ok.example.com", "organization-domain-verify", text: "Verify again"

      stub_dns(FakeDnsResolver.new)
      perform_enqueued_jobs do
        post verify_organization_domain_path(@organization, verified)
      end

      refute_predicate verified.reload, :verified?
      assert_equal 1, verified.checks.count
    end

    should "404 for a removed domain and enqueue nothing" do
      @domain.remove!(actor: @owner)

      assert_no_difference -> { OrganizationDomainCheck.count } do
        post verify_organization_domain_path(@organization, @domain)
      end
      assert_response :not_found
      assert_no_enqueued_jobs only: OrganizationDomainVerificationJob
      assert_empty @resolver.queries
    end
  end

  context "remove" do
    should "delete the domain and its checks and record a removed event for the owner" do
      domain = create(:organization_domain, organization: @organization, domain: "example.com")
      create(:organization_domain_check, organization_domain: domain)
      sign_in @owner

      assert_difference ["OrganizationDomain.count", "OrganizationDomainCheck.count"], -1 do
        delete organization_domain_path(@organization, domain)
      end

      assert_redirected_to edit_organization_path(@organization)
      refute OrganizationDomain.exists?(domain.id)
      assert_empty @organization.domains
      additional = @organization.events.where(tag: Events::OrganizationEvent::DOMAIN_REMOVED).sole.additional

      assert_equal "example.com", additional.domain
      assert_equal @owner.to_gid, additional.actor_gid
    end

    should "404 on a second delete of the same domain and record one removed event" do
      domain = create(:organization_domain, organization: @organization, domain: "example.com")
      sign_in @owner
      delete organization_domain_path(@organization, domain)

      assert_redirected_to edit_organization_path(@organization)

      delete organization_domain_path(@organization, domain)

      assert_response :not_found
      assert_equal 1, @organization.events.where(tag: Events::OrganizationEvent::DOMAIN_REMOVED).count
    end

    should "let another organization add and verify the domain after removal" do
      domain = create(:organization_domain, :verified, organization: @organization, domain: "example.com")
      sign_in @owner
      delete organization_domain_path(@organization, domain)
      other = create(:organization_domain, organization: create(:organization), domain: "example.com")

      assert other.update(verified_at: Time.zone.now)
      refute_equal domain.token, other.token
    end

    should "404 for an already removed domain" do
      domain = create(:organization_domain, organization: @organization, domain: "example.com")
      domain.remove!(actor: @owner)
      sign_in @owner

      assert_no_difference -> { @organization.events.count } do
        delete organization_domain_path(@organization, domain)
      end

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
        assert OrganizationDomain.exists?(@domain.id)
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
      assert_no_enqueued_jobs only: OrganizationDomainVerificationJob
      assert_nil victim.reload.check_queued_at
      assert OrganizationDomain.exists?(victim.id)
      refute_predicate victim, :verified?
    end
  end

  context "adding a domain concurrently" do
    should "re-render with a taken error instead of a 500 when the add race is lost" do
      create(:organization_domain, organization: @organization, domain: "example.com")
      ActiveRecord::Validations::UniquenessValidator.any_instance.stubs(:validate_each)
      sign_in @owner

      assert_no_difference ["OrganizationDomain.count", "Events::OrganizationEvent.count"] do
        post organization_domains_path(@organization), params: { organization_domain: { domain: "example.com" } }
      end

      assert_response :unprocessable_content
      testid "organization-domain-input"
    end
  end

  context "locale keys" do
    should "exist for every outcome and be gone for the old codes and groups" do
      (OrganizationDomainCheck.outcomes.keys - ["matched"]).each do |outcome|
        assert I18n.exists?("organizations.domains.failure.#{outcome}"), "missing #{outcome}"
      end
      %w[error_codes error_groups verify_result detail].each do |key|
        refute I18n.exists?("organizations.domains.#{key}"), "stale key #{key}"
      end
    end

    should "keep button labels as strings in every locale file" do
      I18n.available_locales.each do |locale|
        BUTTON_KEYS.each do |key|
          assert_kind_of String, I18n.t("organizations.domains.#{key}", locale:), "#{locale} #{key}"
        end
      end
    end

    should "render for every outcome on the settings page" do
      sign_in @owner
      OrganizationDomainCheck.outcomes.each_key do |outcome|
        next if outcome == "matched"

        domain = create(:organization_domain, organization: @organization, last_check_result: "failure")
        create(:organization_domain_check, :failure, organization_domain: domain, outcome:)
      end
      get edit_organization_path(@organization)

      assert_response :success
      testid "organization-domain-failure", count: 3

      refute_match(/translation missing|translation_missing/i, response.body)
    end
  end
end
