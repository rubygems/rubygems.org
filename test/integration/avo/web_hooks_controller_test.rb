require "test_helper"

class Avo::WebHooksControllerTest < ActionDispatch::IntegrationTest
  include AdminHelpers

  test "getting web_hooks as admin" do
    admin_sign_in_as create(:admin_github_user, :is_admin)

    get avo.resources_web_hooks_path

    assert_response :success

    web_hook = create(:web_hook)

    get avo.resources_web_hooks_path

    assert_response :success
    page.assert_text web_hook.url

    get avo.resources_web_hook_path(web_hook)

    assert_response :success
    page.assert_text web_hook.url
  end
end
