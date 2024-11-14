require "test_helper"

class Avo::AttestationsControllerTest < ActionDispatch::IntegrationTest
  include AdminHelpers

  test "getting attestations as admin" do
    admin_sign_in_as create(:admin_github_user, :is_admin)

    get avo.resources_attestations_path

    assert_response :success

    attestation = create(:attestation)

    get avo.resources_attestations_path

    assert_response :success
    page.assert_text attestation.media_type

    get avo.resources_attestation_path(attestation)

    assert_response :success
    page.assert_text attestation.media_type
  end
end
