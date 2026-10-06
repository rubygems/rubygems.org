# frozen_string_literal: true

require "test_helper"

class EmailConfirmationsWebauthnControllerTest < ActionController::TestCase
  tests EmailConfirmationsController

  test "WebAuthn verification completes and consumes email confirmation" do
    user = create(:user, :unconfirmed)
    credential = create(:webauthn_credential, user:)
    token = user.issue_email_confirmation!(user.email)

    get :update, params: { token: }
    post :confirm, params: { confirmation: session[:email_confirmation_id] }

    assert_response :success
    challenge = session[:webauthn_authentication]["challenge"]
    origin = WebAuthn.configuration.allowed_origins.first
    client = WebAuthn::FakeClient.new(origin, encoding: false)
    WebauthnHelpers.create_credential(webauthn_credential: credential, client:)

    post :webauthn_update, params: {
      confirmation: session[:email_confirmation_id],
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
    post :confirm, params: { confirmation: session[:email_confirmation_id] }
    origin = WebAuthn.configuration.allowed_origins.first
    client = WebAuthn::FakeClient.new(origin, encoding: false)
    WebauthnHelpers.create_credential(webauthn_credential: credential, client:)

    user_state = user.reload.attributes
    credential_state = credential.reload.attributes
    post :webauthn_update, params: { confirmation: session[:email_confirmation_id] }

    assert_response :unauthorized
    assert_equal user_state, user.reload.attributes
    assert_equal credential_state, credential.reload.attributes

    post :webauthn_update, params: {
      confirmation: session[:email_confirmation_id],
      credentials: WebauthnHelpers.get_result(client:, challenge: SecureRandom.hex)
    }

    assert_response :unauthorized
    assert_equal user_state, user.reload.attributes
    assert_equal credential_state, credential.reload.attributes
    assert user.valid_email_confirmation_token?(token)
  end

  test "an expired WebAuthn session denies valid credentials without changing confirmation authority" do
    user = create(:user, :unconfirmed)
    credential = create(:webauthn_credential, user:)
    token = user.issue_email_confirmation!(user.email)

    get :update, params: { token: }
    post :confirm, params: { confirmation: session[:email_confirmation_id] }
    challenge = session[:webauthn_authentication]["challenge"]
    origin = WebAuthn.configuration.allowed_origins.first
    client = WebAuthn::FakeClient.new(origin, encoding: false)
    WebauthnHelpers.create_credential(webauthn_credential: credential, client:)
    credentials = WebauthnHelpers.get_result(client:, challenge:)
    user_state = user.reload.attributes
    credential_state = credential.reload.attributes

    travel 16.minutes do
      post :webauthn_update, params: { confirmation: session[:email_confirmation_id], credentials: }
    end

    assert_redirected_to root_path
    assert_equal I18n.t("multifactor_auths.session_expired"), flash[:alert]
    assert_nil session[:mfa_expires_at]
    assert_equal user_state, user.reload.attributes
    assert_equal credential_state, credential.reload.attributes
    assert user.valid_email_confirmation_token?(token)
  end

  test "token replacement before WebAuthn submission prevents confirmation" do
    user = create(:user, :unconfirmed)
    credential = create(:webauthn_credential, user:)
    token = user.issue_email_confirmation!(user.email)

    get :update, params: { token: }
    post :confirm, params: { confirmation: session[:email_confirmation_id] }
    challenge = session[:webauthn_authentication]["challenge"]
    origin = WebAuthn.configuration.allowed_origins.first
    client = WebAuthn::FakeClient.new(origin, encoding: false)
    WebauthnHelpers.create_credential(webauthn_credential: credential, client:)
    user.issue_email_confirmation!(user.email)
    sign_count = credential.reload.sign_count

    post :webauthn_update, params: {
      confirmation: session[:email_confirmation_id],
      credentials: WebauthnHelpers.get_result(client:, challenge:)
    }

    assert_redirected_to root_path
    refute_predicate user.reload, :email_confirmed?
    assert_equal sign_count, credential.reload.sign_count
  end
end
