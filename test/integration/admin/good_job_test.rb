require "test_helper"

class Admin::GoodJobTest < ActionDispatch::IntegrationTest
  include AdminHelpers

  test "viewing good job admin dashboard" do
    get "/admin/good_job"

    assert_response :success
    page.assert_text "Log in with GitHub"

    admin = create(:admin_github_user, :is_admin)
    admin_sign_in_as admin

    get "/admin/good_job/jobs"

    assert_response :success
    page.assert_text "GoodJob 👍"
  end
end
