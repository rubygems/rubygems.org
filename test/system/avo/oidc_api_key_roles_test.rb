require "application_system_test_case"

class Avo::OIDCApiKeyRolesSystemTest < ApplicationSystemTestCase
  make_my_diffs_pretty!

  def sign_in_as(user)
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github",
      uid: "1",
      credentials: {
        token: user.oauth_token,
        expires: false
      },
      info: {
        name: user.login
      }
    )

    stub_github_info_request(user.info_data)

    visit avo.root_path
    click_button "Log in with GitHub"

    page.assert_text user.login
  end

  test "manually changing roles" do
    admin_user = create(:admin_github_user, :is_admin)
    sign_in_as admin_user

    provider = create(:oidc_provider)
    user = create(:user)

    visit avo.resources_oidc_api_key_roles_path
    click_on "Create new oidc api key role"

    select provider.issuer, from: "oidc_api_key_role_oidc_provider_id"
    find_field(id: "oidc_api_key_role_user_id").click
    send_keys user.display_handle
    find("li", text: user.display_handle).click
    fill_in "Name", with: "Role"
    fill_in "Valid for", with: "PT15M"
    fill_in "Comment", with: "A nice long comment"

    click_on "Save"

    page.assert_text "can't be blank"
    page.assert_text "Access policy can't be blank"

    assert_field "oidc_api_key_role_oidc_provider_id", with: provider.id
    assert_field "oidc_api_key_role_user_id", with: user.display_handle
    assert_field "Name", with: "Role"
    assert_field "Valid for", with: "900"

    find("div[data-field-id='scopes'] tags").click
    send_keys "push_rubygem", :enter
    fill_in "Comment", with: "A nice long comment"

    click_on "Add another Statement"
    click_on "Add another Condition"

    click_on "Save"

    fill_in "oidc_api_key_role_access_policy_statements_0__principal_oidc", with: provider.issuer
    select "String Matches", from: "oidc_api_key_role_access_policy_statements_0__conditions_0__operator"
    fill_in "oidc_api_key_role_access_policy_statements_0__conditions_0__claim", with: "sub"
    fill_in "oidc_api_key_role_access_policy_statements_0__conditions_0__value", with: "sub-value"
    fill_in "Comment", with: "A nice long comment"

    click_on "Save"

    page.assert_text "Role"

    role = provider.api_key_roles.sole

    assert_equal "string_matches", role.access_policy.statements[0].conditions[0].operator
    assert_equal OIDC::ApiKeyPermissions.new(valid_for: 15.minutes, gems: [], scopes: ["push_rubygem"]), role.api_key_permissions
  end
end
