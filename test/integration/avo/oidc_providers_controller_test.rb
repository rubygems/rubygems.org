require "test_helper"

class Avo::OIDCProvidersControllerTest < ActionDispatch::IntegrationTest
  include AdminHelpers

  test "getting providers as admin" do
    admin_sign_in_as create(:admin_github_user, :is_admin)

    get avo.resources_oidc_providers_path

    assert_response :success

    oidc_provider = create(:oidc_provider)

    get avo.resources_oidc_providers_path

    assert_response :success
    page.assert_text oidc_provider.issuer

    get avo.resources_oidc_provider_path(oidc_provider)

    assert_response :success
    page.assert_text oidc_provider.issuer
  end
end
