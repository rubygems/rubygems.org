require "securerandom"
require "test_helper"
require "webauthn/fake_client"

class Internal::WebauthnRegistrationsControllerTest < ActionController::TestCase
  context "when logged in" do
    setup do
      @user = create(:user)
      sign_in_as(@user)
    end

    context "when webauthn enabled" do
      setup do
        @fake_client = WebAuthn::FakeClient.new("http://test.host", encoding: :base64url)
        public_key_credential = WebAuthn::PublicKeyCredential.from_create(@fake_client.create)
        encoder = WebAuthn::Encoder.new
        @user.webauthn_credentials.create(
          external_id: public_key_credential.id,
          public_key: encoder.encode(public_key_credential.public_key),
          nickname: "USB key"
        )
        @user.webauthn_handle = encoder.encode(SecureRandom.random_bytes(64))
        @user.save!(validate: false)
      end

      context "on GET to /webauthn_registration/options" do
        setup do
          @previous_webauthn_handle = @user.webauthn_handle
          get :options
        end

        should respond_with :success
        should "not change webauthn handle" do
          assert_equal @previous_webauthn_handle, @user.webauthn_handle
        end
      end
    end

    context "when webauthn disabled" do
      context "on GET to /webauthn_registration/options" do
        setup do
          get :options
        end

        should "set webauthn handle to user" do
          assert @user.webauthn_handle
        end
      end

      context "on POST to /webauthn_registration" do
        setup do
          challenge = SecureRandom.random_bytes(32)
          @encoder = WebAuthn::Encoder.new
          fake_client = WebAuthn::FakeClient.new("http://test.host", encoding: :base64url)
          @controller.session[:webauthn_challenge] = @encoder.encode(challenge)

          @handle = SecureRandom.random_bytes(64)
          @user.update(webauthn_handle: @encoder.encode(@handle))
          @client_credential = fake_client.create(challenge: challenge)
          params = @client_credential
          params["nickname"] = "A nickname"

          post :create, params: params
        end

        should respond_with :success
        should "create a credential" do
          assert_equal 1, @user.webauthn_credentials.count
          credential = @user.webauthn_credentials.take
          assert_equal @client_credential["rawId"], credential.external_id
          assert credential.public_key
        end
      end
    end
  end
end
