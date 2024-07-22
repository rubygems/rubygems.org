require "test_helper"

class Api::V1::OIDC::TrustedPublisherControllerTest < ActionDispatch::IntegrationTest
  setup do
    @pkey = OpenSSL::PKey::RSA.generate(2048)
    create(:oidc_provider, issuer: OIDC::Provider::GITHUB_ACTIONS_ISSUER, pkey: @pkey)

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

    travel_to Time.zone.at(1_680_020_830) # after the JWT iat, before the exp
  end

  def jwt(claims = @claims, key: @pkey)
    JSON::JWT.new(claims).sign(key.to_jwk)
  end

  context "POST exchange_token" do
    should "return not found with no matching trusted publisher" do
      post api_v1_oidc_trusted_publisher_exchange_token_path,
        params: { jwt: jwt.to_s }

      assert_response :not_found
    end

    should "return not found when owner has changed" do
      trusted_publisher = build(:oidc_trusted_publisher_github_action,
        repository_name: "oidc-test",
        repository_owner_id: "123",
        workflow_filename: "token.yml")
      trusted_publisher.repository_owner = "segiddins"
      trusted_publisher.save!
      post api_v1_oidc_trusted_publisher_exchange_token_path,
        params: { jwt: jwt.to_s }

      assert_response :not_found
    end

    should "return not found with an unknown issuer" do
      @claims["iss"] = "https://unknown.example.com"
      trusted_publisher = build(:oidc_trusted_publisher_github_action,
        repository_name: "oidc-test",
        repository_owner_id: "1946610",
        workflow_filename: "token.yml")
      trusted_publisher.repository_owner = "segiddins"
      trusted_publisher.save!
      post api_v1_oidc_trusted_publisher_exchange_token_path,
        params: { jwt: jwt.to_s }

      assert_response :not_found
    end

    should "return not found with an unsupported issuer" do
      @claims["iss"] = "https://unknown.example.com"
      create(:oidc_provider, issuer: @claims["iss"], pkey: @pkey)
      trusted_publisher = build(:oidc_trusted_publisher_github_action,
        repository_name: "oidc-test",
        repository_owner_id: "1946610",
        workflow_filename: "token.yml")
      trusted_publisher.repository_owner = "segiddins"
      trusted_publisher.save!
      post api_v1_oidc_trusted_publisher_exchange_token_path,
        params: { jwt: jwt.to_s }

      assert_response :not_found
    end

    should "return bad request with an invalid JWT" do
      post api_v1_oidc_trusted_publisher_exchange_token_path,
        params: { jwt: "invalid" }

      assert_response :bad_request
    end

    should "return bad request with invalid JSON" do
      post api_v1_oidc_trusted_publisher_exchange_token_path,
        params: { jwt: "a.a.a" }

      assert_response :bad_request
    end

    should "return not found when time is before nbf" do
      @claims["nbf"] += 1_000_000
      trusted_publisher = build(:oidc_trusted_publisher_github_action,
        repository_name: "oidc-test",
        repository_owner_id: "1946610",
        workflow_filename: "token.yml")
      trusted_publisher.repository_owner = "segiddins"
      trusted_publisher.save!
      post api_v1_oidc_trusted_publisher_exchange_token_path,
        params: { jwt: jwt.to_s }

      assert_response :not_found
    end

    should "return not found when time is after exp" do
      @claims["exp"] -= 1_000_000
      trusted_publisher = build(:oidc_trusted_publisher_github_action,
        repository_name: "oidc-test",
        repository_owner_id: "1946610",
        workflow_filename: "token.yml")
      trusted_publisher.repository_owner = "segiddins"
      trusted_publisher.save!
      post api_v1_oidc_trusted_publisher_exchange_token_path,
        params: { jwt: jwt.to_s }

      assert_response :not_found
    end

    should "return not found when signature validation fails" do
      @claims["exp"] -= 1_000_000
      trusted_publisher = build(:oidc_trusted_publisher_github_action,
        repository_name: "oidc-test",
        repository_owner_id: "1946610",
        workflow_filename: "token.yml")
      trusted_publisher.repository_owner = "segiddins"
      trusted_publisher.save!
      post api_v1_oidc_trusted_publisher_exchange_token_path,
        params: { jwt: jwt(key: OpenSSL::PKey::RSA.generate(2048)).to_s }

      assert_response :not_found
    end

    should "return not found when workflow is from a different ref" do
      @claims["job_workflow_ref"] = "segiddins/oidc-test/.github/workflows/token.yml@refs/heads/other"
      trusted_publisher = build(:oidc_trusted_publisher_github_action,
        repository_name: "oidc-test",
        repository_owner_id: "1946610",
        workflow_filename: "token.yml")
      trusted_publisher.repository_owner = "segiddins"
      trusted_publisher.save!
      post api_v1_oidc_trusted_publisher_exchange_token_path,
        params: { jwt: jwt.to_s }

      assert_response :not_found
    end

    should "return not found when audience is wrong" do
      @claims["aud"] = "other.com"
      trusted_publisher = build(:oidc_trusted_publisher_github_action,
        repository_name: "oidc-test",
        repository_owner_id: "123",
        workflow_filename: "token.yml")
      trusted_publisher.repository_owner = "segiddins"
      trusted_publisher.save!
      post api_v1_oidc_trusted_publisher_exchange_token_path,
        params: { jwt: jwt.to_s }

      assert_response :not_found
    end

    should "return not found when issuer has no jwks and jwt is unsigned" do
      trusted_publisher = build(:oidc_trusted_publisher_github_action,
        repository_name: "oidc-test",
        repository_owner_id: "1946610",
        workflow_filename: "token.yml")
      trusted_publisher.repository_owner = "segiddins"
      trusted_publisher.save!

      OIDC::Provider.github_actions.update!(jwks: nil)

      post api_v1_oidc_trusted_publisher_exchange_token_path,
        params: { jwt: JSON::JWT.new(@claims).to_s }

      assert_response :not_found
    end

    should "succeed with matching trusted publisher" do
      trusted_publisher = build(:oidc_trusted_publisher_github_action,
        repository_name: "oidc-test",
        repository_owner_id: "1946610",
        workflow_filename: "token.yml")
      trusted_publisher.repository_owner = "segiddins"
      trusted_publisher.save!
      post api_v1_oidc_trusted_publisher_exchange_token_path,
        params: { jwt: jwt.to_s }

      assert_response :success

      resp = response.parsed_body

      assert_match(/^rubygems_/, resp["rubygems_api_key"])
      assert_equal({
                     "rubygems_api_key" => resp["rubygems_api_key"],
                      "name" => "GitHub Actions segiddins/oidc-test @ .github/workflows/token.yml 2023-03-28T16:22:17Z",
                      "scopes" => ["push_rubygem"],
                      "expires_at" => 15.minutes.from_now
                   }, resp)

      api_key = trusted_publisher.api_keys.sole

      assert_equal api_key.owner, trusted_publisher
    end
  end
end
