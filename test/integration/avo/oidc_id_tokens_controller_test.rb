require "test_helper"

class Avo::OIDCIdTokensControllerTest < ActionDispatch::IntegrationTest
  include AdminHelpers

  test "getting id tokens as admin" do
    admin_sign_in_as create(:admin_github_user, :is_admin)

    get avo.resources_oidc_id_tokens_path

    assert_response :success

    oidc_id_token = create(:oidc_id_token)

    get avo.resources_oidc_id_tokens_path

    assert_response :success
    page.assert_text oidc_id_token.api_key.name

    get avo.resources_oidc_id_token_path(oidc_id_token)

    assert_response :success
    page.assert_text oidc_id_token.jwt["claims"].values.first
  end
end
