require "test_helper"

class Avo::WebauthnCredentialsControllerTest < ActionDispatch::IntegrationTest
  include AdminHelpers

  test "getting webauthn credentials as admin" do
    admin_sign_in_as create(:admin_github_user, :is_admin)

    webauthn_credential = create(:webauthn_credential)

    get avo.resources_webauthn_credential_path(webauthn_credential)

    assert_response :success
    page.assert_text webauthn_credential.external_id
  end
end
