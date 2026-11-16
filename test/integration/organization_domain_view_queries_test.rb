# frozen_string_literal: true

require "test_helper"

class OrganizationDomainViewQueriesTest < ActionDispatch::IntegrationTest
  setup do
    @owner = create(:user)
    @organization = create(:organization, owners: [@owner], handle: "arrakis", name: "Arrakis")
    verified = create(:organization_domain, :verified, organization: @organization, domain: "arrakis.example.com")
    create(:organization_domain_check, organization_domain: verified)
    failed = create(:organization_domain, organization: @organization, domain: "docs.arrakis.example.com",
      last_check_result: "failure")
    create(:organization_domain_check, :failure, organization_domain: failed)
    create(:organization_domain, organization: @organization, domain: "deleted.example.com").destroy_with_audit!(actor: @owner)
  end

  test "the public organization pages load no domain data and show no domains" do
    [organization_path(@organization), organization_gems_path(@organization)].each do |path|
      assert_no_domain_queries { get path }

      assert_response :success
      refute_match(/arrakis\.example\.com/, response.body)
    end
  end

  test "the members page loads no domain data and shows no domains" do
    sign_in @owner

    assert_no_domain_queries { get organization_memberships_path(@organization) }

    assert_response :success
    refute_match(/arrakis\.example\.com/, response.body)
  end

  test "the settings page renders the domains card without querying from views" do
    sign_in @owner

    assert_no_domain_queries_from_views { get edit_organization_path(@organization) }

    assert_response :success
    assert_select "[data-testid=?]", "organization-domain", count: 2
    assert_select "[data-testid=?]", "organization-domain-failure", count: 1
  end

  test "re-rendering settings after an invalid domain does not query from views" do
    sign_in @owner

    assert_no_domain_queries_from_views do
      post organization_domains_path(@organization), params: { organization_domain: { domain: "https://bad" } }
    end

    assert_response :unprocessable_content
    assert_select "[data-testid=?]", "organization-domain", count: 2
  end

  test "re-rendering settings after an invalid name does not query from views" do
    sign_in @owner

    assert_no_domain_queries_from_views do
      patch organization_path(@organization), params: { organization: { name: "" } }
    end

    assert_select "[data-testid=?]", "organization-domain", count: 2
  end

  test "a successful name update loads no settings-card domain data" do
    sign_in @owner
    check_queries = []
    callback = ->(*, payload) { check_queries << payload[:sql] if payload[:sql].include?("organization_domain_checks") }

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      patch organization_path(@organization), params: { organization: { name: "Arrakis Renamed" } }
    end

    assert_redirected_to organization_path(@organization)
    assert_empty check_queries
  end

  private

  def sign_in(user)
    post session_path(session: { who: user.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })
  end

  def assert_no_domain_queries(&)
    domain_queries = []
    callback = ->(*, payload) { domain_queries << payload[:sql] if payload[:sql].include?("organization_domain") }

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record", &)

    assert_empty domain_queries, "Expected no organization domain queries"
  end

  def assert_no_domain_queries_from_views(&)
    view_queries = []
    callback = lambda do |*, payload|
      next unless payload[:sql].include?("organization_domain")

      view_frame = caller.find { |line| line.include?("/app/views/") }
      view_queries << "#{payload[:sql]}\n  from #{view_frame}" if view_frame
    end

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record", &)

    assert_empty view_queries, "Expected no organization domain queries from views"
  end
end
