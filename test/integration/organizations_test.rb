# frozen_string_literal: true

require "test_helper"

class OrganizationsTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, remember_token_expires_at: Gemcutter::REMEMBER_FOR.from_now)
    post session_path(session: { who: @user.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })
  end

  test "should show an organization" do
    organization = create(:organization, owners: [@user], handle: "arrakis", name: "Arrakis")
    organization.rubygems << create(:rubygem, name: "arrakis", number: "1.0.0")

    get organization_path(organization)

    assert_response :success
    assert page.has_content? "arrakis"
  end

  test "should show an organization when signed out" do
    organization = create(:organization, owners: [@user], handle: "arrakis", name: "Arrakis")
    delete sign_out_path

    get organization_path(organization)

    assert_response :success
  end

  test "should render not found when an organization doesn't exist" do
    get organization_path("nonexistent")

    assert_response :not_found
  end

  test "should list no organization for a user with none" do
    get "/organizations"

    assert_response :success
    assert page.has_content? "You are not a member of any organizations."
  end

  test "should list organizations for a user" do
    organization = create(:organization, owners: [@user])

    get organizations_path

    assert_response :success
    assert page.has_content? organization.name
  end

  test "should render organization edit form" do
    organization = create(:organization, owners: [@user])

    get edit_organization_path(organization)

    assert_response :success
    assert_select "form[action=?]", organization_path(organization)
    assert_select "input[name=?]", "organization[name]"
  end

  test "should update an organization display name" do
    organization = create(:organization, owners: [@user])

    patch organization_path(organization), params: {
      organization: { name: "New Name" }
    }

    assert_redirected_to organization_path(organization)
    follow_redirect!

    assert page.has_content? "New Name"
  end

  test "should render the domain verification form on the edit page" do
    organization = create(:organization, owners: [@user])

    get edit_organization_path(organization)

    assert_response :success
    assert_select "input[name=?]", "organization[domain]"
  end

  test "should not render the DNS record until a domain is claimed" do
    organization = create(:organization, owners: [@user])

    get edit_organization_path(organization)

    assert_response :success
    assert_select "[data-testid=?]", "dns-record", false
  end

  test "should render the DNS record to publish once a domain is claimed" do
    organization = create(:organization, owners: [@user], domain: "arrakis.example.com")

    get edit_organization_path(organization)

    assert_response :success
    assert_select "[data-testid=?]", "dns-record-name", text: "arrakis.example.com"
    assert_select "[data-testid=?]", "dns-record-value", text: organization.dns_txt_record_value
    assert_select "[data-testid=?]", "dns-verification-status", text: /Not verified/
  end

  test "should render the verified status once the domain is verified" do
    organization = create(:organization, owners: [@user], domain: "arrakis.example.com")
    organization.dns_verification_succeeded!

    get edit_organization_path(organization)

    assert_response :success
    assert_select "[data-testid=?]", "dns-verification-status", text: /Verified/
  end

  test "should let an owner claim a domain" do
    organization = create(:organization, owners: [@user])

    patch organization_path(organization), params: {
      organization: { domain: "arrakis.example.com" }
    }

    assert_redirected_to organization_path(organization)
    assert_equal "arrakis.example.com", organization.reload.domain
    assert_predicate organization.dns_verification_token, :present?
    refute_predicate organization, :dns_verified?
  end

  test "should re-render the form when the claimed domain is invalid" do
    organization = create(:organization, owners: [@user])

    patch organization_path(organization), params: {
      organization: { domain: "not a domain" }
    }

    assert_response :success
    assert_select "[data-testid=?]", "domain-error"
    assert_nil organization.reload.domain
  end

  test "should not let an admin claim a domain" do
    organization = create(:organization, admins: [@user], domain: "arrakis.example.com")
    organization.dns_verification_succeeded!

    patch organization_path(organization), params: {
      organization: { domain: "caladan.example.com" }
    }

    assert_response :forbidden
    assert_equal "arrakis.example.com", organization.reload.domain
    assert_predicate organization, :dns_verified?
  end

  test "should not let a maintainer claim a domain" do
    organization = create(:organization, maintainers: [@user])

    patch organization_path(organization), params: {
      organization: { domain: "arrakis.example.com" }
    }

    assert_response :forbidden
    assert_nil organization.reload.domain
    assert_nil organization.dns_verification_token
  end

  test "should not let a non-member claim a domain" do
    organization = create(:organization, owners: [create(:user)])

    patch organization_path(organization), params: {
      organization: { domain: "arrakis.example.com" }
    }

    assert_response :forbidden
    assert_nil organization.reload.domain
    assert_nil organization.dns_verification_token
  end

  test "should not let a signed out user claim a domain" do
    organization = create(:organization, owners: [@user])
    delete sign_out_path

    patch organization_path(organization), params: {
      organization: { domain: "arrakis.example.com" }
    }

    assert_response :forbidden
    assert_nil organization.reload.domain
    assert_nil organization.dns_verification_token
  end

  test "should not expose the DNS record or verification status to a non-member" do
    organization = create(:organization, owners: [create(:user)], domain: "arrakis.example.com")

    get edit_organization_path(organization)

    assert_response :forbidden
    refute page.has_content? organization.dns_verification_token
  end

  test "should render user roles for users in the organization" do
    organization = create(:organization, owners: [@user])

    get organization_path(organization)

    assert page.has_content? "#{@user.handle} owner", normalize_ws: true
  end

  test "should not render user roles for users outside the organization" do
    owner = create(:user)
    organization = create(:organization, owners: [owner])

    get organization_path(organization)

    refute page.has_content? "#{owner.handle} owner", normalize_ws: true
  end

  test "should render an invite button for admins+" do
    organization = create(:organization, owners: [@user])

    get organization_path(organization)

    assert_select "a[href=?]", new_organization_membership_path(organization), text: "Invite"
  end

  test "should not render the invite button for users with less access than admins" do
    organization = create(:organization, maintainers: [@user])

    get organization_path(organization)

    refute page.has_content? "Invite"
  end
end
