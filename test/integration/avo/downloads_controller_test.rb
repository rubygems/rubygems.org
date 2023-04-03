require "test_helper"

class Avo::GemDownloadsControllerTest < ActionDispatch::IntegrationTest
  include AdminHelpers

  test "getting downloads as admin" do
    admin_sign_in_as create(:admin_github_user, :is_admin)

    get avo.resources_downloads_path

    assert_response :success

    version = create(:version)
    download = create(:download, version: version)

    get avo.resources_downloads_path

    assert_response :success
    page.assert_text download.downloads.to_s

    get avo.resources_download_path(download)

    assert_response :success
    page.assert_text download.downloads.to_s
  end
end
