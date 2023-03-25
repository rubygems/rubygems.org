require "test_helper"

class Avo::LinksetTest < ActionDispatch::IntegrationTest
  include AdminHelpers

  test "getting linksets as admin" do
    admin_sign_in_as create(:admin_github_user, :is_admin)

    get avo.resources_linksets_path

    assert_response :success

    linkset = create(:linkset)

    get avo.resources_linksets_path

    assert_response :success
    assert page.has_content? linkset.rubygem.name

    get avo.resources_linkset_path(linkset)

    assert_response :success
    assert page.has_content? linkset.rubygem.name
  end
end
