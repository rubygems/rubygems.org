require "test_helper"

class Avo::OIDCRubygemTrustedPublishersControllerTest < ActionDispatch::IntegrationTest
  include AdminHelpers

  test "getting rubygem trusted publishers as admin" do
    admin_sign_in_as create(:admin_github_user, :is_admin)

    get avo.resources_oidc_rubygem_trusted_publishers_path

    assert_response :success

    oidc_rubygem_trusted_publisher = create(:oidc_rubygem_trusted_publisher)

    get avo.resources_oidc_rubygem_trusted_publishers_path

    assert_response :success
    page.assert_text oidc_rubygem_trusted_publisher.rubygem.name
    page.assert_text oidc_rubygem_trusted_publisher.trusted_publisher.name

    get avo.resources_oidc_rubygem_trusted_publisher_path(oidc_rubygem_trusted_publisher)

    assert_response :success
    page.assert_text oidc_rubygem_trusted_publisher.rubygem.name
    page.assert_text oidc_rubygem_trusted_publisher.trusted_publisher.name
  end
end
