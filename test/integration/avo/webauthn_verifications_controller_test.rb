require "test_helper"

class Avo::WebauthnVerificationsControllerTest < ActionDispatch::IntegrationTest
  include AdminHelpers

  test "getting webauthn verifications as admin" do
    admin_sign_in_as create(:admin_github_user, :is_admin)

    webauthn_verification = create(:webauthn_verification)

    get avo.resources_webauthn_verification_path(webauthn_verification)

    assert_response :success
    page.assert_text webauthn_verification.path_token
  end
end
