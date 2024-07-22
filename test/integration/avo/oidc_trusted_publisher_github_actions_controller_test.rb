require "test_helper"

class Avo::OIDCTrustedPublisherGitHubActionsControllerTest < ActionDispatch::IntegrationTest
  include AdminHelpers

  test "getting github actions trusted publishers as admin" do
    admin_sign_in_as create(:admin_github_user, :is_admin)

    get avo.resources_oidc_trusted_publisher_github_actions_path

    assert_response :success

    oidc_trusted_publisher_github_action = create(:oidc_trusted_publisher_github_action)

    get avo.resources_oidc_trusted_publisher_github_actions_path

    assert_response :success
    page.assert_text oidc_trusted_publisher_github_action.repository_owner

    get avo.resources_oidc_trusted_publisher_github_action_path(oidc_trusted_publisher_github_action)

    assert_response :success
    page.assert_text oidc_trusted_publisher_github_action.repository_owner
  end
end
