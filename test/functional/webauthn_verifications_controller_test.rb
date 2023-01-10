require "test_helper"

class WebauthnVerificationsControllerTest < ActionController::TestCase
  context "#prompt" do
    context "when given an expired webauthn token" do
      setup do
        @user = create(:user)
        token = create(:webauthn_verification, user: @user, path_token_expires_at: 1.minute.ago).path_token
        get :prompt, params: { webauthn_token: token }
      end

      should "return a 404" do
        assert_response :not_found
      end
    end

    context "when given an invalid webauthn token" do
      setup do
        @user = create(:user)
        get :prompt, params: { webauthn_token: "not_valid1234" }
      end

      should "return a 404" do
        assert_response :not_found
      end
    end

    context "when given a valid webauthn token param" do
      setup do
        @user = create(:user)
        @token = create(:webauthn_verification, user: @user).path_token
      end

      context "with webauthn devices enabled" do
        setup do
          create(:webauthn_credential, user: @user)
          get :prompt, params: { webauthn_token: @token }
        end

        should respond_with :success
        should "set webauthn authentication" do
          assert_not_nil session[:webauthn_authentication]["challenge"]
        end

        should "render the verification page" do
          assert page.has_content?("Authenticate with Security Device")
        end

        should "set the user" do
          assert page.has_content?(@user.name)
        end

        should "provide the verification button" do
          assert page.has_button?("Authenticate")
        end
      end

      context "with no webauthn devices enabled" do
        setup do
          get :prompt, params: { webauthn_token: @token }
        end

        should respond_with :redirect
        should redirect_to("the homepage") { root_url }
        should "display error that user has no webauthn devices enabled" do
          assert_equal "You don't have any security devices enabled", flash[:alert]
        end
      end
    end
  end

  context "#authenticate" do
    setup do
      @user = create(:user)
      @webauthn_credential = create(:webauthn_credential, user: @user)
      @token = create(:webauthn_verification, user: @user).path_token
      get :prompt, params: { webauthn_token: @token }
    end

    context "when verifying the challenge" do
      setup do
        @challenge = session[:webauthn_authentication]["challenge"]
        @origin = "http://localhost:3000"
        @rp_id = URI.parse(@origin).host
        @client = WebAuthn::FakeClient.new(@origin, encoding: false)
        WebauthnHelpers.create_credential(
          webauthn_credential: @webauthn_credential,
          client: @client
        )
        post(
          :authenticate,
          params: {
            credentials:
              WebauthnHelpers.get_result(
                client: @client,
                challenge: @challenge
              ),
            webauthn_token: @token
          },
          format: :json
        )
      end

      should respond_with :success
      should "return success message" do
        assert_equal "success", JSON.parse(response.body)["message"]
      end
    end

    context "when not providing credentials" do
      setup do
        post(
          :authenticate,
          params: {
            webauthn_token: @token
          },
          format: :json
        )
      end

      should respond_with :unauthorized
      should "return error message" do
        assert_equal "Credentials required", JSON.parse(response.body)["message"]
      end
    end

    context "when providing wrong credentials" do
      setup do
        @wrong_challenge = "16b8e11ea1b46abc64aea3ecdac1c418"
        @origin = "http://localhost:3000"
        @rp_id = URI.parse(@origin).host
        @client = WebAuthn::FakeClient.new(@origin, encoding: false)
        WebauthnHelpers.create_credential(
          webauthn_credential: @webauthn_credential,
          client: @client
        )
        post(
          :authenticate,
          params: {
            credentials:
              WebauthnHelpers.get_result(
                client: @client,
                challenge: @wrong_challenge
              ),
            webauthn_token: @token
          },
          format: :json
        )
      end

      should respond_with :unauthorized
      should "return error message" do
        assert_equal "WebAuthn::ChallengeVerificationError", JSON.parse(response.body)["message"]
      end
    end

    context "when given an invalid webauthn token" do
      setup do
        @wrong_webuthn_token = "pRpwn2mTH2D18t58"
        @challenge = session[:webauthn_authentication]["challenge"]
        @origin = "http://localhost:3000"
        @rp_id = URI.parse(@origin).host
        @client = WebAuthn::FakeClient.new(@origin, encoding: false)
        WebauthnHelpers.create_credential(
          webauthn_credential: @webauthn_credential,
          client: @client
        )
        post(
          :authenticate,
          params: {
            credentials:
              WebauthnHelpers.get_result(
                client: @client,
                challenge: @challenge
              ),
            webauthn_token: @wrong_webuthn_token
          },
          format: :json
        )
      end

      should respond_with :not_found
    end
  end
end
