require "test_helper"

class Avo::VersionsTest < ActionDispatch::IntegrationTest
  include AdminHelpers

  test "getting versions as admin" do
    admin_sign_in_as create(:admin_github_user, :is_admin)

    get avo.resources_versions_path
    assert_response :success

    version = create(:version)

    get avo.resources_versions_path
    assert_response :success
    assert page.has_content? version.full_name

    get avo.resources_version_path(version)
    assert_response :success
    assert page.has_content? version.full_name
  end
end
