require "test_helper"

class Api::V1::GithubSecretScanningTest < ActionDispatch::IntegrationTest
  HEADER_KEYID = "GITHUB-PUBLIC-KEY-IDENTIFIER".freeze
  HEADER_SIGNATURE = "GITHUB-PUBLIC-KEY-SIGNATURE".freeze

  KEYS_RESPONSE_BODY =
    { "public_keys" => [
      {
        "key_identifier" => "test_key_id",
        "is_current" => true
      }
    ] }.freeze

  context "on POST to revoke" do
    setup do
      key = OpenSSL::PKey::EC.new("secp256k1").generate_key
      @private_key_pem = key.to_pem
      pkey = OpenSSL::PKey::EC.new(key.public_key.group)
      pkey.public_key = key.public_key
      @public_key_pem = pkey.to_pem

      h = KEYS_RESPONSE_BODY.dup
      h["public_keys"][0]["key"] = @public_key_pem
      GithubSecretScanning.stubs(:secret_scanning_keys).returns(JSON.dump(h))

      @tokens = [
        { "token" => "some_token", "type" => "some_type", "url" => "some_url" }
      ]

      @user = create(:user)
    end

    context "with no key_id" do
      setup do
        post revoke_api_v1_api_key_path(@rubygem),
          params: {},
          headers: { HEADER_SIGNATURE => "bar" }
      end

      should "deny access" do
        assert_response 401
        assert_match "Missing GitHub Signature", @response.body
      end
    end

    context "with no signature" do
      setup do
        post revoke_api_v1_api_key_path(@rubygem),
          params: {},
          headers: { HEADER_KEYID => "foo" }
      end

      should "deny access" do
        assert_response 401
        assert_match "Missing GitHub Signature", @response.body
      end
    end

    context "with invalid key_id" do
      setup do
        post revoke_api_v1_api_key_path(@rubygem),
          params: {},
          headers: { HEADER_KEYID => "foo", HEADER_SIGNATURE => "bar" }
      end

      should "deny access" do
        assert_response 401
        assert_match "Can't fetch public key from GitHub", @response.body
      end
    end

    context "with invalid signature" do
      setup do
        signature = sign_body("Hello world!")
        post revoke_api_v1_api_key_path(@rubygem),
          params: {},
          headers: { HEADER_KEYID => "test_key_id", HEADER_SIGNATURE => Base64.encode64(signature) }
      end

      should "deny access" do
        assert_response 401
        assert_match "Invalid GitHub Signature", @response.body
      end
    end

    context "without a valid token" do
      setup do
        signature = sign_body(JSON.dump(@tokens))
        post revoke_api_v1_api_key_path(@rubygem),
          params: @tokens,
          headers: { HEADER_KEYID => "test_key_id", HEADER_SIGNATURE => Base64.encode64(signature) },
          as: :json
      end

      should "returns success" do
        assert_response :success
        json = JSON.parse(@response.body)[0]
        assert_equal "false_positive", json["label"]
        assert_equal @tokens[0]["type"], json["token_type"]
        assert_equal @tokens[0]["token"], json["token_raw"]
      end
    end

    context "with a valid token" do
      setup do
        key = "rubygems_#{SecureRandom.hex(24)}"
        @api_key = create(:api_key, key: key)
        @tokens << { "token" => key, "type" => "rubygems", "url" => "some_url" }
        signature = sign_body(JSON.dump(@tokens))

        post revoke_api_v1_api_key_path(@rubygem),
          params: @tokens,
          headers: { HEADER_KEYID => "test_key_id", HEADER_SIGNATURE => Base64.encode64(signature) },
          as: :json

        Delayed::Worker.new.work_off
      end

      should "returns success and remove the token" do
        assert_response :success

        json = JSON.parse(@response.body)
        assert_equal "true_positive", json.last["label"]
        assert_equal @tokens.last["token"], json.last["token_raw"]

        assert_raises(ActiveRecord::RecordNotFound) { @api_key.reload }
      end

      should "delivers an email" do
        refute_empty ActionMailer::Base.deliveries
        email = ActionMailer::Base.deliveries.last
        assert_equal [@api_key.user.email], email.to
        assert_equal ["no-reply@mailer.rubygems.org"], email.from
        assert_equal "One of your API keys was revoked on rubygems.org", email.subject
        assert_match "some_url", email.body.to_s
      end
    end
  end

  private

  def sign_body(body)
    private_key = OpenSSL::PKey::EC.new(@private_key_pem)
    private_key.sign(OpenSSL::Digest.new("SHA256"), body)
  end
end
