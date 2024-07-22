require "test_helper"

class Api::V1::OIDC::ProvidersTest < ActionDispatch::IntegrationTest
  make_my_diffs_pretty!

  setup do
    @providers = create_list(:oidc_provider, 3)

    @user = create(:user)
    @user_api_key = "12323"
    @api_key = create(:api_key, owner: @user, key: @user_api_key)
  end

  context "on GET to index" do
    should "return all providers" do
      get api_v1_oidc_providers_path,
        params: {},
        headers: { "HTTP_AUTHORIZATION" => @user_api_key }

      assert_response :success
    end
  end

  context "on GET to show" do
    should "return provider" do
      get api_v1_oidc_provider_path(@providers[1]),
        params: {},
        headers: { "HTTP_AUTHORIZATION" => @user_api_key }

      assert_response :success
    end
  end
end
