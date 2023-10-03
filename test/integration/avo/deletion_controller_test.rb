require "test_helper"

class Avo::DeletionControllerTest < ActionDispatch::IntegrationTest
  include AdminHelpers

  test "getting deletion as admin" do
    admin_sign_in_as create(:admin_github_user, :is_admin)

    get avo.resources_deletions_path

    assert_response :success

    deletion = create(:deletion)

    get avo.resources_deletions_path

    assert_response :success
    assert page.has_content? deletion.id

    get avo.resources_deletion_path(deletion)

    assert_response :success
    assert page.has_content? deletion.id
  end
end
