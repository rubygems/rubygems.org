require "test_helper"

class Api::V1::OIDC::IdTokensTest < ActionDispatch::IntegrationTest
  make_my_diffs_pretty!

  setup do
    @role = create(:oidc_api_key_role)
    @user = @role.user
    @id_token = create(:oidc_id_token, user: @user, api_key_role: @role)

    @user_api_key = "12323"
    @api_key = create(:api_key, user: @user, key: @user_api_key)
  end

  context "on GET to index" do
    should "return the user's roles" do
      get api_v1_oidc_id_tokens_path,
              params: {},
              headers: { "HTTP_AUTHORIZATION" => @user_api_key }

      assert_response :success
      assert_equal [
        {
          "provider_id" => @id_token.provider.id,
          "api_key_role_token" => @id_token.api_key_role.token,
          "jwt" => {
            "claims" => @id_token.jwt["claims"],
            "header" => @id_token.jwt["header"]
          }
        }
      ], response.parsed_body
    end
  end

  context "on GET to show" do
    should "return the user's id token" do
      get api_v1_oidc_id_token_path(@id_token),
              params: {},
              headers: { "HTTP_AUTHORIZATION" => @user_api_key }

      assert_response :success
      assert_equal(
        {
          "provider_id" => @id_token.provider.id,
          "api_key_role_token" => @id_token.api_key_role.token,
          "jwt" => {
            "claims" => @id_token.jwt["claims"],
            "header" => @id_token.jwt["header"]
          }
        }, response.parsed_body
      )
    end
  end
end
