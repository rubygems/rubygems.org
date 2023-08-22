require "test_helper"

class Avo::RubygemsTest < ActionDispatch::IntegrationTest
  include AdminHelpers

  test "getting rubygems as admin" do
    admin_sign_in_as create(:admin_github_user, :is_admin)

    get avo.resources_rubygems_path

    assert_response :success

    rubygem = create(:rubygem)

    get avo.resources_rubygems_path

    assert_response :success
    assert page.has_content? rubygem.name

    get avo.resources_rubygem_path(rubygem.id)

    assert_response :success
    assert page.has_content? rubygem.name
  end
end
