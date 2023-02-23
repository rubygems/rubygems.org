require "test_helper"

class Avo::AdminGitHubUsersTest < ActionDispatch::IntegrationTest
  include AdminHelpers

  test "getting admin github users as admin" do
    user = create(:admin_github_user, :is_admin)
    admin_sign_in_as user

    get avo.resources_admin_github_users_path
    assert_response :success
    assert page.has_content? user.login
    assert page.has_content? user.github_id

    get avo.resources_admin_github_user_path(user)
    assert_response :success
    assert page.has_content? user.name
    assert page.has_content? user.github_id
  end
end
