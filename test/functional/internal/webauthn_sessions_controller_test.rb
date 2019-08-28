require "test_helper"
require "webauthn/fake_client"
require "securerandom"

class Internal::WebauthnSessionsControllerTest < ActionController::TestCase
  context "when user has webauthn enabled" do
    setup do
      @encoder = WebAuthn::Encoder.new
      @user = User.new(email_confirmed: true)
      @user.webauthn_handle = @encoder.encode(SecureRandom.random_bytes(64))
      @user.save!(validate: false)
      @fake_client = WebAuthn::FakeClient.new("http://test.host", encoding: :base64url)
      public_key_credential = WebAuthn::PublicKeyCredential.from_create(@fake_client.create)
      @user.webauthn_credentials.create!(
        external_id: public_key_credential.id,
        public_key: @encoder.encode(public_key_credential.public_key),
        nickname: "A nickname",
        sign_count: 0
      )
    end

    context "on POST to /webauthn_session" do
      setup do
        @controller.session[:mfa_user] = @user.handle
        @challenge = SecureRandom.random_bytes(32)
        @controller.session[:webauthn_challenge] = @encoder.encode(@challenge)
      end

      context "when authentication succeeds" do
        setup do
          @sign_count = 1234
          @client_credential = @fake_client.get(challenge: @challenge, sign_count: @sign_count)

          post :create, params: @client_credential
        end

        should respond_with :success
        should "redirect to the dashboard" do
          assert_equal JSON.parse(response.body)["redirect_path"], "/"
        end

        should "clear user name in session" do
          assert @controller.session[:mfa_user].nil?
        end

        should "make user logged in" do
          assert @controller.request.env[:clearance].signed_in?
        end

        should "update sign count" do
          actual_sign_count = WebauthnCredential.find_by(external_id: @client_credential["id"]).sign_count
          assert_equal @sign_count, actual_sign_count
        end
      end

      context "when authentication fails" do
        setup do
          wrong_challenge = SecureRandom.random_bytes(32)
          @client_credential = @fake_client.get(challenge: wrong_challenge, sign_count: 1)

          post :create, params: @client_credential
        end

        should set_flash[:error]
        should respond_with :unauthorized
        should "attempt to redirect to sign in page" do
          assert_equal JSON.parse(response.body)["redirect_path"], "/sign_in"
        end

        should "not sign in the user" do
          refute @controller.request.env[:clearance].signed_in?
        end

        should "clear user name in session" do
          assert_nil @controller.session[:mfa_user]
        end

        should "not update sign count" do
          actual_sign_count = WebauthnCredential.find_by(external_id: @client_credential["id"]).sign_count
          assert_equal 0, actual_sign_count
        end
      end

      context "when webauthn user handle is incorrect" do
        setup do
          credentials = @fake_client.get(challenge: @challenge)
          credentials["response"]["userHandle"] = @encoder.encode(SecureRandom.random_bytes(64))

          post :create, params: credentials
        end

        should respond_with :unauthorized
      end

      context "when sign count is missing" do
        setup do
          @client_credential = @fake_client.get(challenge: @challenge)

          post :create, params: @client_credential
        end

        should respond_with :success
        should "redirect to the dashboard" do
          assert_equal JSON.parse(response.body)["redirect_path"], "/"
        end

        should "clear user name in session" do
          assert @controller.session[:mfa_user].nil?
        end

        should "make user logged in" do
          assert @controller.request.env[:clearance].signed_in?
        end
      end
    end
  end
end
