require "test_helper"
require "webauthn/fake_client"
require "securerandom"

class Internal::WebauthnSessionsControllerTest < ActionController::TestCase
  context "when user has webauthn enabled" do
    setup do
      @user = User.new(email_confirmed: true)
      @user.webauthn_handle = WebAuthn.generate_user_id
      @user.save!(validate: false)
      @fake_client = WebAuthn::FakeClient.new("http://test.host")
      public_key_credential = WebAuthn::Credential.from_create(@fake_client.create)
      @user.webauthn_credentials.create!(
        external_id: public_key_credential.id,
        public_key: public_key_credential.public_key,
        nickname: "A nickname",
        sign_count: 0,
        last_used_on: Time.current
      )
    end

    context "on GET to /webauthn_session/options" do
      setup do
        get :options
      end

      should respond_with :success
      should "only allow existing credentials" do
        credential_id = JSON.parse(@response.body)["allowCredentials"][0]["id"]
        assert_equal credential_id, @user.webauthn_credentials.take.external_id
      end
    end

    context "on POST to /webauthn_session" do
      setup do
        @challenge = WebAuthn::Credential.options_for_get.challenge
        @controller.session[:webauthn_challenge] = @challenge
        @controller.session[:mfa_user] = @user.handle
      end

      context "when authentication succeeds" do
        setup do
          @sign_count = 1234
          @client_credential = @fake_client.get(challenge: @challenge, sign_count: @sign_count)

          post :create, params: @client_credential
        end

        should respond_with :success
        should "redirect to the dashboard" do
          assert_equal "/", JSON.parse(response.body)["redirect_path"]
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

        should "set 'last used on'" do
          last_used_on = WebauthnCredential.find_by(external_id: @client_credential["id"]).last_used_on
          assert last_used_on
        end
      end

      context "when authentication fails" do
        setup do
          @client_credential = @fake_client.get(sign_count: 1)

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
          credentials["response"]["userHandle"] = WebAuthn.generate_user_id

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
