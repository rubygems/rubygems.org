require "test_helper"

class Api::V1::OIDC::ApiKeyRolesTest < ActionDispatch::IntegrationTest
  make_my_diffs_pretty!

  def jwt(claims = @claims, key: @pkey)
    JSON::JWT.new(claims).sign(key.to_jwk)
  end

  context "on POST to assume_role" do
    setup do
      @pkey = OpenSSL::PKey::RSA.generate(2048)
      @role = create(:oidc_api_key_role, provider: build(:oidc_provider, issuer: "https://token.actions.githubusercontent.com", pkey: @pkey))
      @user = @role.user

      @claims = {
        "aud" => "https://github.com/segiddins",
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
         "workflow" => ".github/workflows/token.yml",
         "event_name" => "push",
         "repository" => "segiddins/oidc-test",
         "run_number" => "4",
         "run_attempt" => "1",
         "workflow_ref" =>
          "segiddins/oidc-test/.github/workflows/token.yml@refs/heads/main",
         "workflow_sha" => "04de3558bc5861874a86f8fcd67e516554101e71",
         "repository_id" => "620393838",
         "job_workflow_ref" =>
          "segiddins/oidc-test/.github/workflows/token.yml@refs/heads/main",
         "job_workflow_sha" => "04de3558bc5861874a86f8fcd67e516554101e71",
         "repository_owner" => "segiddins",
         "runner_environment" => "github-hosted",
         "repository_owner_id" => "1946610",
         "repository_visibility" => "public"
      }

      travel_to Time.zone.at(1_680_020_830) # after the JWT iat, before the exp
    end

    context "with an unknown id" do
      should "response not found" do
        post assume_role_api_v1_oidc_api_key_role_path(@role.id + 1),
            params: {},
            headers: {}

        assert_response :not_found
      end
    end

    context "with a known id" do
      context "with an invalid jwt" do
        should "respond not found" do
          post assume_role_api_v1_oidc_api_key_role_path(@role),
              params: {
                jwt: "1#{jwt}"
              },
              headers: {}

          assert_response :not_found
          assert_empty @user.api_keys
        end
      end

      context "with a jwt that does not match the jwks" do
        should "respond not found" do
          @role.provider.jwks.each { _1["n"] += "NO" }
          @role.provider.save!

          post assume_role_api_v1_oidc_api_key_role_path(@role),
              params: {
                jwt: jwt.to_s
              },
              headers: {}

          assert_response :not_found
          assert_empty @user.api_keys
        end
      end

      context "with a jwt with the wrong issuer" do
        should "respond not found" do
          @role.provider.configuration.issuer = "https://example.com"
          @role.provider.update!(issuer: "https://example.com")

          post assume_role_api_v1_oidc_api_key_role_path(@role),
              params: {
                jwt: jwt.to_s
              },
              headers: {}

          assert_response :not_found
          assert_empty @user.api_keys
        end
      end

      context "with matching conditions" do
        should "return API key" do
          @role.access_policy.statements.first.conditions << OIDC::AccessPolicy::Statement::Condition.new(
            operator: "string_equals",
            claim: "sub",
            value: "repo:segiddins/oidc-test:ref:refs/heads/main"
          )
          @role.save!

          post assume_role_api_v1_oidc_api_key_role_path(@role),
              params: {
                jwt: jwt.to_s
              },
              headers: {}

          assert_response :created

          resp = response.parsed_body

          assert_match(/^rubygems_/, resp["rubygems_api_key"])
          assert_equal({
                         "rubygems_api_key" => resp["rubygems_api_key"],
              "name" => "GitHub Pusher-79685b65-945d-450a-a3d8-a36bcf72c23d",
              "scopes" => ["push_rubygem"],
              "expires_at" => 30.minutes.from_now
                       }, resp)
          hashed_key = @user.api_keys.sole.hashed_key

          assert_equal hashed_key, Digest::SHA256.hexdigest(resp["rubygems_api_key"])
        end
      end

      context "with mismatched conditions" do
        should "return not found" do
          @role.access_policy.statements.first.conditions << OIDC::AccessPolicy::Statement::Condition.new(
            operator: "string_equals",
            claim: "sub",
            value: "repo:other/oidc-test:ref:refs/heads/main"
          )
          @role.save!

          post assume_role_api_v1_oidc_api_key_role_path(@role),
              params: {
                jwt: jwt.to_s
              },
              headers: {}

          assert_response :not_found
          assert_empty @user.api_keys
        end
      end

      should "return an API token" do
        post assume_role_api_v1_oidc_api_key_role_path(@role),
            params: {
              jwt: jwt.to_s
            },
            headers: {}

        assert_response :created

        resp = response.parsed_body

        assert_match(/^rubygems_/, resp["rubygems_api_key"])
        assert_equal({
                       "rubygems_api_key" => resp["rubygems_api_key"],
            "name" => "GitHub Pusher-79685b65-945d-450a-a3d8-a36bcf72c23d",
            "scopes" => ["push_rubygem"],
            "expires_at" => 30.minutes.from_now
                     }, resp)
        hashed_key = @user.api_keys.sole.hashed_key

        assert_equal hashed_key, Digest::SHA256.hexdigest(resp["rubygems_api_key"])

        oidc_id_token = @role.id_tokens.sole

        assert_equal hashed_key, oidc_id_token.api_key.hashed_key
        assert_equal @role.provider, oidc_id_token.provider
        assert_equal(
          {
            "claims" => @claims,
            "header" => {
              "alg" => "RS256",
              "kid" => @pkey.to_jwk[:kid],
              "typ" => "JWT"
            }
          },
                     oidc_id_token.jwt
        )

        post assume_role_api_v1_oidc_api_key_role_path(@role),
            params: {
              jwt: jwt.to_s
            },
            headers: {}

        assert_response :unprocessable_entity
        assert_equal({
                       "errors" => { "jwt.claims.jti" => ["must be unique"] }
                     }, response.parsed_body)
      end
    end
  end
end
