require "test_helper"

class OrganizationsTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, remember_token_expires_at: Gemcutter::REMEMBER_FOR.from_now)
    post session_path(session: { who: @user.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })
  end

  test "should show an organization" do
    organization = create(:organization, owners: [@user], handle: "arrakis", name: "Arrakis")
    organization.rubygems << create(:rubygem, name: "arrakis", number: "1.0.0")

    get "/organizations/#{organization.to_param}"

    assert_response :success
    assert page.has_content? "arrakis"
  end

  test "should render not found when an organization doesn't exist" do
    get "/organizations/notfound"

    assert_response :not_found
  end

  test "should list no organization for a user with none" do
    get "/organizations"

    assert_response :success
  end

  test "should list organizations for a user" do
    organization = create(:organization, owners: [@user])

    get "/organizations"

    assert_response :success
    assert page.has_content? organization.name
  end

  test "should render organization edit form" do
    organization = create(:organization, owners: [@user])

    get "/organizations/#{organization.to_param}/edit"

    assert_response :success
    assert_select "form[action=?]", organization_path(organization)
    assert_select "input[name=?]", "organization[name]"
  end

  test "should update an organization display name" do
    organization = create(:organization, owners: [@user])

    patch "/organizations/#{organization.to_param}", params: {
      organization: { name: "New Name" }
    }

    assert_redirected_to organization_path(organization)
    follow_redirect!

    assert page.has_content? "New Name"
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

    assert page.has_content? "Invite"
  end

  test "should not render the invite button for users with less access than admins" do
    organization = create(:organization, maintainers: [@user])

    get organization_path(organization)

    refute page.has_content? "Invite"
  end
end
