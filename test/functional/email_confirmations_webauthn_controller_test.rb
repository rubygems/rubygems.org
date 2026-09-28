# frozen_string_literal: true

require "test_helper"

class EmailConfirmationsWebauthnControllerTest < ActionController::TestCase
  tests EmailConfirmationsController

  test "WebAuthn verification completes and consumes email confirmation" do
    user = create(:user, :unconfirmed)
    credential = create(:webauthn_credential, user:)
    token = user.issue_email_confirmation!(user.email)

    get :update, params: { token: }
    post :confirm

    assert_response :success
    challenge = session[:webauthn_authentication]["challenge"]
    origin = WebAuthn.configuration.allowed_origins.first
    client = WebAuthn::FakeClient.new(origin, encoding: false)
    WebauthnHelpers.create_credential(webauthn_credential: credential, client:)

    post :webauthn_update, params: {
      credentials: WebauthnHelpers.get_result(client:, challenge:)
    }

    assert_redirected_to sign_in_path
    assert_predicate user.reload, :email_confirmed?
    assert_nil user.email_confirmation_token_digest
  end

  test "WebAuthn denials leave the email confirmation unconsumed" do
    user = create(:user, :unconfirmed)
    credential = create(:webauthn_credential, user:)
    token = user.issue_email_confirmation!(user.email)

    get :update, params: { token: }
    post :confirm
    origin = WebAuthn.configuration.allowed_origins.first
    client = WebAuthn::FakeClient.new(origin, encoding: false)
    WebauthnHelpers.create_credential(webauthn_credential: credential, client:)

    post :webauthn_update

    assert_response :unauthorized

    post :webauthn_update, params: {
      credentials: WebauthnHelpers.get_result(client:, challenge: SecureRandom.hex)
    }

    assert_response :unauthorized
    refute_predicate user.reload, :email_confirmed?
    assert user.valid_email_confirmation_token?(token)
  end

  test "token replacement before WebAuthn submission prevents confirmation" do
    user = create(:user, :unconfirmed)
    credential = create(:webauthn_credential, user:)
    token = user.issue_email_confirmation!(user.email)

    get :update, params: { token: }
    post :confirm
    challenge = session[:webauthn_authentication]["challenge"]
    origin = WebAuthn.configuration.allowed_origins.first
    client = WebAuthn::FakeClient.new(origin, encoding: false)
    WebauthnHelpers.create_credential(webauthn_credential: credential, client:)
    user.issue_email_confirmation!(user.email)

    post :webauthn_update, params: {
      credentials: WebauthnHelpers.get_result(client:, challenge:)
    }

    assert_redirected_to root_path
    refute_predicate user.reload, :email_confirmed?
  end
end
