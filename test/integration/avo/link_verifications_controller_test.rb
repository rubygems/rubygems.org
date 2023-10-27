require "test_helper"

class Avo::LinkVerificationsControllerTest < ActionDispatch::IntegrationTest
  include AdminHelpers

  test "getting link_verifications as admin" do
    admin_sign_in_as create(:admin_github_user, :is_admin)

    get avo.resources_link_verifications_path

    assert_response :success

    link_verification = create(:link_verification)

    get avo.resources_link_verifications_path

    assert_response :success
    page.assert_text link_verification.uri

    get avo.resources_link_verification_path(link_verification)

    assert_response :success
    page.assert_text link_verification.uri
  end
end
