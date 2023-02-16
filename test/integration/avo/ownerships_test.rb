require "test_helper"

class Avo::RubygemsTest < ActionDispatch::IntegrationTest
  include AdminHelpers

  test "getting ownerships as admin" do
    admin_sign_in_as create(:admin_github_user, :is_admin)

    get avo.resources_ownerships_path
    assert_response :found

    ownership = create(:ownership)

    get avo.resources_ownerships_path
    assert_response :found

    get avo.resources_ownership_path(ownership)
    assert_response :success
    page.assert_text ownership.user.name
    page.assert_text ownership.rubygem.name
  end
end
