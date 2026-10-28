# frozen_string_literal: true

require "test_helper"

class Api::V1::OIDC::IdTokensTest < ActionDispatch::IntegrationTest
  make_my_diffs_pretty!

  setup do
    @role = create(:oidc_api_key_role)
    @user = @role.user
    @id_token = create(:oidc_id_token, user: @user, api_key_role: @role)

    @user_api_key = "12323"
    @api_key = create(:api_key, owner: @user, key: @user_api_key, scopes: %w[access_oidc_api_key_roles])
  end

  def self.should_forbid_keys_without_account_wide_scope(&request)
    should "forbid an api key with only the index_rubygems scope" do
      forbidden_key = create(:api_key, owner: @user, key: "forbidden", scopes: %w[index_rubygems])

      assert_forbidden_without_leaking(forbidden_key, &request)
    end

    should "forbid an api key with only the show_dashboard scope" do
      forbidden_key = create(:api_key, owner: @user, key: "forbidden", scopes: %w[show_dashboard])

      assert_forbidden_without_leaking(forbidden_key, &request)
    end

    should "forbid an api key with only the configure_trusted_publishers scope" do
      forbidden_key = create(:api_key, owner: @user, key: "forbidden", scopes: %w[configure_trusted_publishers])

      assert_forbidden_without_leaking(forbidden_key, &request)
    end

    should "forbid an access_oidc_api_key_roles api key restricted to a gem" do
      rubygem = create(:rubygem, owners: [@user])
      forbidden_key = create(:api_key, owner: @user, key: "forbidden",
                             scopes: %w[access_oidc_api_key_roles push_rubygem], rubygem:)

      assert_forbidden_without_leaking(forbidden_key, &request)
    end
  end

  def assert_forbidden_without_leaking(forbidden_key, &request)
    instance_exec("forbidden", &request)

    assert_response :forbidden
    assert_equal({ "error" => I18n.t(:api_key_insufficient_scope) }, response.parsed_body)
    refute_includes response.body, @role.token
    refute_includes response.body, @id_token.jti
    assert_nil forbidden_key.reload.last_accessed_at, "a refused key must not be marked as used"
  end

  context "on GET to index" do
    should_forbid_keys_without_account_wide_scope do |raw_key|
      get api_v1_oidc_id_tokens_path,
              params: {},
              headers: { "HTTP_AUTHORIZATION" => raw_key }
    end

    should "return the user's roles" do
      get api_v1_oidc_id_tokens_path,
              params: {},
              headers: { "HTTP_AUTHORIZATION" => @user_api_key }

      assert_response :success
      assert_equal [

        "api_key_role_token" => @id_token.api_key_role.token,
        "jwt" => {
          "claims" => @id_token.jwt["claims"],
          "header" => @id_token.jwt["header"]
        }

      ], response.parsed_body
    end
  end

  context "on GET to show" do
    should_forbid_keys_without_account_wide_scope do |raw_key|
      get api_v1_oidc_id_token_path(@id_token),
              params: {},
              headers: { "HTTP_AUTHORIZATION" => raw_key }
    end

    should "forbid before resolving the id, so a refused key cannot probe for one" do
      create(:api_key, owner: @user, key: "forbidden", scopes: %w[index_rubygems])

      get api_v1_oidc_id_token_path(@id_token.id + 1),
              params: {},
              headers: { "HTTP_AUTHORIZATION" => "forbidden" }

      assert_response :forbidden
    end

    should "return the user's id token" do
      get api_v1_oidc_id_token_path(@id_token),
              params: {},
              headers: { "HTTP_AUTHORIZATION" => @user_api_key }

      assert_response :success
      assert_equal_hash(
        { "api_key_role_token" => @id_token.api_key_role.token,
          "jwt" => {
            "claims" => @id_token.jwt["claims"],
            "header" => @id_token.jwt["header"]
          } },
        response.parsed_body
      )
    end
  end
end
