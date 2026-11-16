# frozen_string_literal: true

require "test_helper"

class OrganizationVerifiedDomainsTest < ActionDispatch::IntegrationTest
  setup do
    @organization = create(:organization, owners: [create(:user)], handle: "arrakis", name: "Arrakis")
  end

  test "shows a verified domain" do
    create(:organization_domain, :verified, organization: @organization, domain: "arrakis.example.com")

    get organization_path(@organization)

    assert_response :success
    assert_select "[data-testid=?]", "organization-verified-domains" do
      assert_select "[data-testid=?]", "organization-verified-domain", count: 1, text: /arrakis\.example\.com/
    end
  end

  test "does not show a pending domain" do
    create(:organization_domain, organization: @organization, domain: "pending.example.com")

    get organization_path(@organization)

    assert_response :success
    assert_select "[data-testid=?]", "organization-verified-domains", count: 0
    refute_match(/pending\.example\.com/, response.body)
  end

  test "does not show a domain whose latest check failed after an earlier success" do
    domain = create(:organization_domain, organization: @organization, domain: "lapsed.example.com",
      verified_at: nil, last_check_result: "failure")
    create(:organization_domain_check, organization_domain: domain, checked_at: 2.days.ago)
    create(:organization_domain_check, :failure, organization_domain: domain, checked_at: 1.day.ago)

    get organization_path(@organization)

    assert_response :success
    assert_select "[data-testid=?]", "organization-verified-domains", count: 0
    refute_match(/lapsed\.example\.com/, response.body)
    refute_match(/No TXT records found/, response.body)
  end

  test "shows no indicator for an organization without domains" do
    get organization_path(@organization)

    assert_response :success
    assert_select "[data-testid=?]", "organization-verified-domains", count: 0
  end

  test "shows only verified domains when mixed with others" do
    create(:organization_domain, :verified, organization: @organization, domain: "ok.example.com")
    create(:organization_domain, organization: @organization, domain: "pending.example.com")

    get organization_path(@organization)

    assert_select "[data-testid=?]", "organization-verified-domain", count: 1
    refute_match(/pending\.example\.com/, response.body)
  end
end
