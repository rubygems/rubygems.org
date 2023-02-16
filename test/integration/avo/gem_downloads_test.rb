require "test_helper"

class Avo::RubygemsTest < ActionDispatch::IntegrationTest
  include AdminHelpers

  test "getting gem downloads as admin" do
    admin_sign_in_as create(:admin_github_user, :is_admin)

    get avo.resources_gem_downloads_path
    # assert_response :found

    all_gems_download = create(:gem_download, count: 1234)
    rubygem = create(:rubygem)
    gem_download = rubygem.gem_download
    gem_download.update!(count: 321)
    version = create(:version, rubygem: rubygem)
    version_download = version.gem_download
    version_download.update!(count: 56)

    get avo.resources_gem_downloads_path
    # assert_response :found

    get avo.resources_gem_download_path(all_gems_download)
    assert_response :success
    page.assert_text "All Gems (1,234)"

    get avo.resources_gem_download_path(gem_download)
    assert_response :success
    page.assert_text "#{rubygem.name} (321)"

    get avo.resources_gem_download_path(version_download)
    assert_response :success
    page.assert_text "#{version.full_name} (56)"
  end
end
