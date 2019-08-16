require "securerandom"
require "test_helper"
require "webauthn/fake_client"

class WebauthnCredentialsControllerTest < ActionController::TestCase
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
        @user.credentials.create(
          external_id: public_key_credential.id,
          public_key: encoder.encode(public_key_credential.public_key)
        )
      end

      context "on GET to /webauthn_credentials" do
        setup do
          get :index
        end

        should respond_with :success
        should "list credential" do
          assert page.has_content? "Credential: #{@user.credentials.take.external_id}"
        end
      end
    end

    context "when webauthn disabled" do
      context "on GET to /webauthn_credentials" do
        setup do
          get :index
        end

        should respond_with :success
        should "list no credential" do
          assert page.has_content? "You have no WebAuthn credentials registered yet"
        end
        should "offer to add credentials" do
          assert page.has_button? "Register a WebAuthn credential"
        end
      end

      context "on POST to /webauthn_credentials" do
        setup do
          challenge = SecureRandom.random_bytes(32)
          encoder = WebAuthn::Encoder.new
          fake_client = WebAuthn::FakeClient.new("http://test.host", encoding: :base64url)
          @controller.session[:webauthn_challenge] = encoder.encode(challenge)

          @client_credential = fake_client.create(challenge: challenge)

          post :create, params: @client_credential
        end

        should respond_with :success
        should "create a credential" do
          assert_equal 1, @user.credentials.count
          credential = @user.credentials.take
          assert_equal @client_credential["rawId"], credential.external_id
          assert credential.public_key
        end
      end
    end
  end
end
