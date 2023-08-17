require "test_helper"

class Avo::OIDCApiKeyRolesControllerTest < ActionDispatch::IntegrationTest
  include AdminHelpers

  test "getting api key roles as admin" do
    admin_sign_in_as create(:admin_github_user, :is_admin)

    get avo.resources_oidc_api_key_roles_path

    assert_response :success

    oidc_api_key_role = create(:oidc_api_key_role)

    get avo.resources_oidc_api_key_roles_path

    assert_response :success
    page.assert_text oidc_api_key_role.name

    get avo.resources_oidc_api_key_role_path(oidc_api_key_role)

    assert_response :success
    page.assert_text oidc_api_key_role.name
  end
end
