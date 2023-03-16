require "test_helper"

# Not to be confused with Api::V1::WebauthnVerificationsControllerTest. This is for the UI.

class WebauthnVerificationsControllerTest < ActionController::TestCase
  context "#prompt" do
    context "when given an invalid webauthn token" do
      setup do
        @user = create(:user)
        get :prompt, params: { webauthn_token: "not_valid1234", port: 1 }
      end

      should "return a 404" do
        assert_response :not_found
      end
    end

    context "when the webauthn token has expired" do
      setup do
        @user = create(:user)
        @token = create(:webauthn_verification, user: @user, path_token_expires_at: 1.second.ago).path_token
        get :prompt, params: { webauthn_token: @token }
      end

      should respond_with :redirect
      should redirect_to("the homepage") { root_url }
      should "say the token is consumed or expired" do
        assert_equal "The token in the link you used has either expired or been used already.", flash[:alert]
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
          get :prompt, params: { webauthn_token: @token, port: 1 }
        end

        should respond_with :success
        should "set webauthn authentication" do
          assert_not_nil session[:webauthn_authentication]["challenge"]
          assert_equal "1", session[:webauthn_authentication]["port"]
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

      context "when no port is given" do
        setup do
          create(:webauthn_credential, user: @user)
          get :prompt, params: { webauthn_token: @token }
        end

        should redirect_to("the homepage") { root_url }
        should "display error that no port was given" do
          assert_equal "No port provided. Please try again.", flash[:alert]
        end
      end

      context "with no webauthn devices enabled" do
        setup do
          get :prompt, params: { webauthn_token: @token, port: 1 }
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
      @port = 1
      @verification_created_at = Time.utc(2023, 1, 1, 0, 0, 0)
      travel_to @verification_created_at do
        @verification = create(:webauthn_verification, user: @user, otp: nil, otp_expires_at: nil)
        @token = @verification.path_token
        get :prompt, params: { webauthn_token: @token, port: @port }
      end
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
        @generated_time = Time.utc(2023, 1, 1, 0, 0, 3)
        authenticate_request(time: @generated_time)
        @verification.reload
      end

      should redirect_to("localhost with provided port and verification code") { "http://localhost:#{@port}\?code=#{@verification.otp}" }

      should "set OTP with expiry" do
        assert_equal 16, @user.webauthn_verification.otp.length
        assert_equal @generated_time + 2.minutes, @user.webauthn_verification.otp_expires_at
      end

      should "expire the path token by setting its expiry to 1 second prior" do
        verification = WebauthnVerification.find_by!(path_token: @token)
        assert_equal Time.utc(2023, 1, 1, 0, 0, 2), verification.path_token_expires_at
      end
    end

    context "when not providing credentials" do
      setup do
        travel_to Time.utc(2023, 1, 1, 0, 0, 3) do
          post(
            :authenticate,
            params: {
              webauthn_token: @token
            },
            format: :json
          )
        end
        @verification.reload
      end

      should respond_with :unauthorized
      should "return error message" do
        assert_equal "Credentials required", JSON.parse(response.body)["message"]
      end

      should "not expire the path token" do
        verification = WebauthnVerification.find_by!(path_token: @token)
        assert_equal Time.utc(2023, 1, 1, 0, 2, 0), verification.path_token_expires_at
      end

      should "not generate OTP" do
        assert_nil @verification.otp
        assert_nil @verification.otp_expires_at
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
        authenticate_request(challenge: @wrong_challenge)
        @verification.reload
      end

      should respond_with :unauthorized
      should "return error message" do
        assert_equal "WebAuthn::ChallengeVerificationError", JSON.parse(response.body)["message"]
      end

      should "not generate OTP" do
        assert_nil @verification.otp
        assert_nil @verification.otp_expires_at
      end
    end

    context "when given an invalid webauthn token" do
      setup do
        @wrong_webauthn_token = "pRpwn2mTH2D18t58"
        @challenge = session[:webauthn_authentication]["challenge"]
        @origin = "http://localhost:3000"
        @rp_id = URI.parse(@origin).host
        @client = WebAuthn::FakeClient.new(@origin, encoding: false)
        WebauthnHelpers.create_credential(
          webauthn_credential: @webauthn_credential,
          client: @client
        )
        authenticate_request(token: @wrong_webauthn_token)
      end

      should respond_with :not_found
    end

    context "when the webauthn token has expired" do
      setup do
        @challenge = session[:webauthn_authentication]["challenge"]
        @origin = "http://localhost:3000"
        @rp_id = URI.parse(@origin).host
        @client = WebAuthn::FakeClient.new(@origin, encoding: false)
        WebauthnHelpers.create_credential(
          webauthn_credential: @webauthn_credential,
          client: @client
        )
        authenticate_request(time: Time.utc(2023, 1, 1, 0, 3, 0))
      end

      should respond_with :redirect
      should redirect_to("the homepage") { root_url }
      should "say the token is consumed or expired" do
        assert_equal "The token in the link you used has either expired or been used already.", flash[:alert]
      end
    end

    context "when no port is given" do
      setup do
        @challenge = session[:webauthn_authentication]["challenge"]
        session[:webauthn_authentication]["port"] = nil
        @origin = "http://localhost:3000"
        @rp_id = URI.parse(@origin).host
        @client = WebAuthn::FakeClient.new(@origin, encoding: false)
        WebauthnHelpers.create_credential(
          webauthn_credential: @webauthn_credential,
          client: @client
        )
        authenticate_request
        @verification.reload
      end

      should redirect_to("the homepage") { root_url }
      should "display error that no port was given" do
        assert_equal "No port provided. Please try again.", flash[:alert]
      end
    end
  end

  context "#successful_verification" do
    setup do
      get :successful_verification
    end

    should respond_with :success
    should "set the title and body" do
      assert_includes response.body, "Success!"
      assert_includes response.body, "Please close this browser."
    end
  end

  context "#failed_verification" do
    setup do
      get :failed_verification
    end

    should respond_with :success
    should "set the title and body" do
      assert_includes response.body, "Error - Verification Failed"
      assert_includes response.body, "Please close this browser and try again."
    end
  end

  private

  def authenticate_request(time: @verification_created_at + 3.seconds, token: @token, challenge: @challenge)
    travel_to time do
      post(
        :authenticate,
        params: {
          credentials:
            WebauthnHelpers.get_result(
              client: @client,
              challenge: challenge
            ),
          webauthn_token: token
        },
        format: :json
      )
    end
  end
end
