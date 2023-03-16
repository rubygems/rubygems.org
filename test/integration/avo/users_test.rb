require "test_helper"

class Avo::UsersTest < ActionDispatch::IntegrationTest
  include AdminHelpers

  test "getting users as admin" do
    admin_sign_in_as create(:admin_github_user, :is_admin)

    get avo.resources_users_path

    assert_response :success

    user = create(:user)

    get avo.resources_users_path

    assert_response :success
    assert page.has_content? user.name

    get avo.resources_user_path(user)

    assert_response :success
    assert page.has_content? user.name
  end
end
