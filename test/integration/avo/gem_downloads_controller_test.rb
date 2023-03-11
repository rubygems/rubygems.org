require "test_helper"

class Avo::GemDownloadsControllerTest < ActionDispatch::IntegrationTest
  include AdminHelpers

  test "getting gem_downloads as admin" do
    admin_sign_in_as create(:admin_github_user, :is_admin)

    get avo.resources_gem_downloads_path

    assert_response :success

    version = create(:version)
    gem_download = version.gem_download
    GemDownload.bulk_update([[version.full_name, 100]])

    get avo.resources_gem_downloads_path

    assert_response :success
    page.assert_text gem_download.count.to_s

    get avo.resources_gem_download_path(gem_download)

    assert_response :success
    page.assert_text gem_download.count.to_s
  end
end
