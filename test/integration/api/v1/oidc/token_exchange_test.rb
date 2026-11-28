# frozen_string_literal: true

require "test_helper"

class Api::V1::OIDC::TokenExchangeTest < ActionDispatch::IntegrationTest
  setup do
    @pkey = OpenSSL::PKey::RSA.generate(2048)
    @provider = create(:oidc_provider, issuer: OIDC::Provider::GITHUB_ACTIONS_ISSUER, pkey: @pkey)

    @claims = {
      "aud" => Gemcutter::HOST,
      "exp" => 1_680_020_837,
      "iat" => 1_680_020_537,
      "iss" => "https://token.actions.githubusercontent.com",
      "jti" => "79685b65-945d-450a-a3d8-a36bcf72c23d",
      "nbf" => 1_680_019_937,
      "ref" => "refs/heads/main",
      "sha" => "04de3558bc5861874a86f8fcd67e516554101e71",
      "sub" => "repo:segiddins/oidc-test:ref:refs/heads/main",
      "actor" => "segiddins",
      "run_id" => "4545231084",
      "actor_id" => "1946610",
      "base_ref" => "",
      "head_ref" => "",
      "ref_type" => "branch",
      "workflow" => "token",
      "event_name" => "push",
      "repository" => "segiddins/oidc-test",
      "run_number" => "4",
      "run_attempt" => "1",
      "workflow_ref" => "segiddins/oidc-test/.github/workflows/token.yml@refs/heads/main",
      "workflow_sha" => "04de3558bc5861874a86f8fcd67e516554101e71",
      "repository_id" => "620393838",
      "job_workflow_ref" => "segiddins/oidc-test/.github/workflows/token.yml@refs/heads/main",
      "job_workflow_sha" => "04de3558bc5861874a86f8fcd67e516554101e71",
      "repository_owner" => "segiddins",
      "runner_environment" => "github-hosted",
      "repository_owner_id" => "1946610",
      "repository_visibility" => "public"
    }

    trusted_publisher = build(:oidc_trusted_publisher_github_action,
      repository_name: "oidc-test",
      repository_owner_id: "1946610",
      workflow_filename: "token.yml")
    trusted_publisher.repository_owner = "segiddins"
    trusted_publisher.save!

    # As the New Role form seeds it: the trusted publishing audience plus a repository binding.
    access_policy = { statements: [
      effect: "allow",
      principal: { oidc: @provider.issuer },
      conditions: [
        { operator: "string_equals", claim: "aud", value: Gemcutter::HOST },
        { operator: "string_equals", claim: "repository", value: "segiddins/oidc-test" }
      ]
    ] }
    @role = create(:oidc_api_key_role, provider: @provider, access_policy:)

    travel_to Time.zone.at(1_680_020_830) # after the JWT iat, before the exp
  end

  def jwt
    JSON::JWT.new(@claims).sign(@pkey.to_jwk).to_s
  end

  test "assume_role refuses a token already exchanged through trusted publishing" do
    post api_v1_oidc_trusted_publisher_exchange_token_path, params: { jwt: }

    assert_response :success

    assert_no_difference ["ApiKey.count", "OIDC::IdToken.count", "OIDC::TokenExchange.count", "Events::UserEvent.count"] do
      assert_no_enqueued_jobs do
        post assume_role_api_v1_oidc_api_key_role_path(@role.token), params: { jwt: }
      end
    end

    assert_response :unprocessable_content
    assert_equal({ "errors" => { "jwt.claims.jti" => ["must be unique"] } }, response.parsed_body)
  end

  test "trusted publishing refuses a token already exchanged through assume_role" do
    post assume_role_api_v1_oidc_api_key_role_path(@role.token), params: { jwt: }

    assert_response :success

    assert_no_difference ["ApiKey.count", "OIDC::TrustedPublisher::IdToken.count", "OIDC::TokenExchange.count"] do
      assert_no_enqueued_jobs do
        post api_v1_oidc_trusted_publisher_exchange_token_path, params: { jwt: }
      end
    end

    assert_response :unprocessable_content
    assert_equal({ "errors" => { "jti" => ["must be unique"] } }, response.parsed_body)
  end

  test "an unrelated unique violation is raised at both endpoints, not reported as a replay" do
    create(:api_key, key: "taken")
    ActiveRecord::Validations::UniquenessValidator.any_instance.stubs(:validate_each)
    [Api::V1::OIDC::TrustedPublisherController, Api::V1::OIDC::ApiKeyRolesController].each do |controller|
      controller.any_instance.stubs(:generate_unique_rubygems_key).returns("taken")
    end

    [api_v1_oidc_trusted_publisher_exchange_token_path, assume_role_api_v1_oidc_api_key_role_path(@role.token)].each do |path|
      assert_no_difference ["ApiKey.count", "OIDC::TokenExchange.count"] do
        error = assert_raises(ActiveRecord::RecordNotUnique) { post path, params: { jwt: } }

        assert_includes error.message, "index_api_keys_on_hashed_key"
      end
    end
  end

  test "each endpoint records when the token it exchanged expires" do
    post api_v1_oidc_trusted_publisher_exchange_token_path, params: { jwt: }

    assert_response :success
    assert_equal Time.zone.at(@claims["exp"]), OIDC::TokenExchange.find_by!(jti: @claims["jti"]).expires_at

    @claims["jti"] = SecureRandom.uuid
    @claims["exp"] += 3600
    post assume_role_api_v1_oidc_api_key_role_path(@role.token), params: { jwt: }

    assert_response :success
    assert_equal Time.zone.at(@claims["exp"]), OIDC::TokenExchange.find_by!(jti: @claims["jti"]).expires_at
  end

  test "pruning straight after an exchange leaves the token refused at the other endpoint" do
    post api_v1_oidc_trusted_publisher_exchange_token_path, params: { jwt: }

    assert_response :success
    assert_equal 0, OIDC::TokenExchange.prune

    assert_no_difference "ApiKey.count" do
      post assume_role_api_v1_oidc_api_key_role_path(@role.token), params: { jwt: }
    end

    assert_response :unprocessable_content
  end

  test "pruning keeps the exchange of a long-lived token until that token expires" do
    @claims["exp"] = 30.days.from_now.to_i
    post api_v1_oidc_trusted_publisher_exchange_token_path, params: { jwt: }

    assert_response :success

    travel 29.days

    assert_equal 0, OIDC::TokenExchange.prune

    assert_no_difference "ApiKey.count" do
      post assume_role_api_v1_oidc_api_key_role_path(@role.token), params: { jwt: }
    end

    assert_response :unprocessable_content
    assert_equal({ "errors" => { "jwt.claims.jti" => ["must be unique"] } }, response.parsed_body)
  end

  test "pruning deletes an exchange only once its token is refused as expired anyway" do
    post api_v1_oidc_trusted_publisher_exchange_token_path, params: { jwt: }

    assert_response :success

    travel_to Time.zone.at(@claims["exp"]) + OIDC::TokenExchange::PRUNE_GRACE + 1.second

    assert_equal 1, OIDC::TokenExchange.prune

    assert_no_difference "ApiKey.count" do
      post assume_role_api_v1_oidc_api_key_role_path(@role.token), params: { jwt: }
    end

    assert_response :not_found
  end
end
