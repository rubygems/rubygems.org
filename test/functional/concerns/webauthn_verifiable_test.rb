require "test_helper"

class TestWebauthnAuthenticationController < ApplicationController
  include WebauthnVerifiable

  def prompt
    @user = User.find(params[:user_id])
    setup_webauthn_authentication(form_url: test_webauthn_authenticate_path)

    render json: { webauthn_options: @webauthn_options.to_json, webauthn_verification_url: @webauthn_verification_url }
  end

  def prompt_with_session_options
    @user = User.find(params[:user_id])
    setup_webauthn_authentication(
      form_url: test_webauthn_authenticate_path,
      session_options: { "foo" => "bar", "baz" => "qux" }
    )

    render json: { webauthn_options: @webauthn_options.to_json, webauthn_verification_url: @webauthn_verification_url }
  end

  def authenticate
    @user = User.find(params[:user_id])
    return render plain: @webauthn_error, status: :unauthorized unless webauthn_credential_verified?

    render plain: "success"
  end
end

class WebauthnVerifiableTest < ActionController::TestCase
  setup do
    @controller = TestWebauthnAuthenticationController.new
    @user = create(:user)
    @webauthn_credential = create(:webauthn_credential, user: @user)

    Rails.application.routes.draw do
      scope controller: "test_webauthn_authentication" do
        get :prompt
        get :prompt_with_session_options
        post :authenticate, as: :test_webauthn_authenticate
      end
    end
  end

  context "#prompt" do
    setup do
      get :prompt, params: { user_id: @user.id }
      @json_response = JSON.parse(@response.body)
    end

    should "set webauthn_verification_url" do
      assert_equal test_webauthn_authenticate_path, @json_response["webauthn_verification_url"]
    end

    should "set webauthn_options" do
      refute_nil @json_response["webauthn_options"]["challenge"]
      refute_nil @json_response["webauthn_options"]["allowCredentials"]
    end

    should "set webauthn_challenge in session" do
      refute_nil session[:webauthn_authentication]["challenge"]
    end
  end

  context "#prompt with session options" do
    setup do
      get :prompt_with_session_options, params: { user_id: @user.id }
    end

    should "set session options in session" do
      assert_equal "bar", session[:webauthn_authentication]["foo"]
      assert_equal "qux", session[:webauthn_authentication]["baz"]
    end
  end

  context "#authenticate" do
    setup do
      get :prompt, params: { user_id: @user.id }
      @challenge = session[:webauthn_authentication]["challenge"]
      @origin = WebAuthn.configuration.origin
      @rp_id = URI.parse(@origin).host
      @client = WebAuthn::FakeClient.new(@origin, encoding: false)
      WebauthnHelpers.create_credential(
        webauthn_credential: @webauthn_credential,
        client: @client
      )
    end

    context "with valid credentials" do
      setup do
        post(
          :authenticate,
          params: {
            credentials:
              WebauthnHelpers.get_result(
                client: @client,
                challenge: @challenge
              ),
            user_id: @user.id
          }
        )
      end

      should "return success" do
        assert_equal "success", @response.body
      end

      should "clear webauthn_authentication in session" do
        assert_nil session[:webauthn_authentication]
      end
    end

    context "with missing credential params" do
      setup do
        post :authenticate, params: { user_id: @user.id }
      end

      should respond_with :unauthorized

      should "return credentials required" do
        assert_equal "Credentials required", @response.body
      end

      should "clear webauthn_authentication in session" do
        assert_nil session[:webauthn_authentication]
      end
    end

    context "when a Webauthn error occurs" do
      setup do
        @wrong_challenge = SecureRandom.hex
        post(
          :authenticate,
          params: {
            credentials:
              WebauthnHelpers.get_result(
                client: @client,
                challenge: @wrong_challenge
              ),
            user_id: @user.id
          }
        )
      end

      should respond_with :unauthorized

      should "return error" do
        assert_equal "WebAuthn::ChallengeVerificationError", @response.body
      end

      should "clear webauthn_authentication in session" do
        assert_nil session[:webauthn_authentication]
      end
    end
  end

  teardown do
    Rails.application.reload_routes!
  end
end
