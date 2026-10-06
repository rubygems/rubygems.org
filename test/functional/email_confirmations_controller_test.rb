# frozen_string_literal: true

require "test_helper"

class EmailConfirmationsControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper
  include ActiveJob::TestHelper
  include UsersHelper

  setup do
    @user = create(:user, :unconfirmed)
    @token = @user.issue_email_confirmation!(@user.email)
  end

  test "opening a confirmation link does not confirm or consume it" do
    get update_email_confirmations_path(token: @token)

    assert_response :success
    assert_select "form[action=?][method=post]", confirm_email_confirmations_path
    refute_predicate @user.reload, :email_confirmed?
    assert @user.valid_email_confirmation_token?(@token)
    assert_email_confirmation_response_headers
    assert_select "[data-testid=email-confirmation-target]", text: obfuscate_email(@user.email)
    assert_select "p", text: I18n.t("email_confirmations.update.email_label")
    refute_includes response.body, @user.email

    get update_email_confirmations_path(token: @token)

    assert_response :success
    refute_predicate @user.reload, :email_confirmed?
  end

  test "confirmation POST consumes the token and replay is denied" do
    begin_email_confirmation

    post confirm_email_confirmations_path, params: { confirmation: session[:email_confirmation_id] }

    assert_redirected_to sign_in_path
    assert_predicate @user.reload, :email_confirmed?
    assert_nil @user.email_confirmation_token_digest
    assert_nil @user.email_confirmation_token_expires_at
    assert_nil @user.email_confirmation_email

    get update_email_confirmations_path(token: @token)

    assert_redirected_to root_path
    assert_equal I18n.t("email_confirmations.update.token_failure"), flash[:alert]
  end

  test "confirmation succeeds with forgery protection and the rendered authenticity token" do
    original_allow_forgery_protection = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true

    get update_email_confirmations_path(token: @token)
    authenticity_token = css_select("form[action='#{confirm_email_confirmations_path}'] input[name=authenticity_token]").sole[:value]
    post confirm_email_confirmations_path, params: { authenticity_token:, confirmation: session[:email_confirmation_id] }

    assert_redirected_to sign_in_path
    assert_predicate @user.reload, :email_confirmed?
    assert_nil @user.email_confirmation_token_digest
  ensure
    ActionController::Base.allow_forgery_protection = original_allow_forgery_protection
  end

  test "opening another user's link does not sign out the current user until confirmation is submitted" do
    other = create(:user)
    post session_path(session: { who: other.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })
    remember_token = other.reload.remember_token

    get update_email_confirmations_path(token: @token)

    assert_response :success
    assert_email_confirmation_response_headers
    assert_equal remember_token, other.reload.remember_token
    refute_predicate @user.reload, :email_confirmed?

    get dashboard_path

    assert_response :success

    post confirm_email_confirmations_path, params: { confirmation: session[:email_confirmation_id] }

    assert_redirected_to sign_in_path
    refute_equal remember_token, other.reload.remember_token
    assert_predicate @user.reload, :email_confirmed?
  end

  test "another user who signs in during the MFA challenge is signed out when confirmation completes" do
    @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
    other = create(:user)

    get update_email_confirmations_path(token: @token)
    post confirm_email_confirmations_path, params: { confirmation: session[:email_confirmation_id] }

    assert_response :success
    post session_path(session: { who: other.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })
    remember_token = other.reload.remember_token

    post otp_update_email_confirmations_path, params: { confirmation: session[:email_confirmation_id], otp: ROTP::TOTP.new(@user.totp_seed).now }

    assert_redirected_to sign_in_path
    refute_equal remember_token, other.reload.remember_token
    assert_predicate @user.reload, :email_confirmed?

    get dashboard_path

    assert_redirected_to sign_in_path
  end

  test "starting the MFA challenge does not sign out another user" do
    @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
    other = create(:user)
    post session_path(session: { who: other.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })
    remember_token = other.reload.remember_token

    get update_email_confirmations_path(token: @token)
    post confirm_email_confirmations_path, params: { confirmation: session[:email_confirmation_id] }

    assert_response :success
    assert_select "h1", text: /Multi-factor authentication/
    refute_predicate @user.reload, :email_confirmed?
    assert_other_user_still_signed_in(other, remember_token)
  end

  test "a wrong OTP does not sign out another user who signed in during the MFA challenge" do
    @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
    other = create(:user)
    get update_email_confirmations_path(token: @token)
    post confirm_email_confirmations_path, params: { confirmation: session[:email_confirmation_id] }
    post session_path(session: { who: other.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })
    remember_token = other.reload.remember_token

    post otp_update_email_confirmations_path, params: { confirmation: session[:email_confirmation_id], otp: "incorrect" }

    assert_response :unauthorized
    refute_predicate @user.reload, :email_confirmed?
    assert @user.valid_email_confirmation_token?(@token)
    assert_other_user_still_signed_in(other, remember_token)
  end

  test "an expired MFA session does not sign out another user who signed in during the MFA challenge" do
    @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
    other = create(:user)
    get update_email_confirmations_path(token: @token)
    post confirm_email_confirmations_path, params: { confirmation: session[:email_confirmation_id] }
    post session_path(session: { who: other.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })
    remember_token = other.reload.remember_token

    travel 16.minutes do
      post otp_update_email_confirmations_path, params: { confirmation: session[:email_confirmation_id], otp: ROTP::TOTP.new(@user.totp_seed).now }

      assert_redirected_to root_path
      assert_equal I18n.t("multifactor_auths.session_expired"), flash[:alert]
      refute_predicate @user.reload, :email_confirmed?
      assert_other_user_still_signed_in(other, remember_token)
    end
  end

  test "an invalid or expired token on the confirmation POST does not sign out another user" do
    other = create(:user)
    post session_path(session: { who: other.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })
    remember_token = other.reload.remember_token

    get update_email_confirmations_path(token: @token)
    @user.update_column(:email_confirmation_token_expires_at, 1.second.ago)
    post confirm_email_confirmations_path, params: { confirmation: session[:email_confirmation_id] }

    assert_redirected_to root_path
    refute_predicate @user.reload, :email_confirmed?
    assert_other_user_still_signed_in(other, remember_token)

    @token = @user.issue_email_confirmation!(@user.email)
    get update_email_confirmations_path(token: @token)
    @user.issue_email_confirmation!(@user.email)
    post confirm_email_confirmations_path, params: { confirmation: session[:email_confirmation_id] }

    assert_redirected_to root_path
    refute_predicate @user.reload, :email_confirmed?
    assert_other_user_still_signed_in(other, remember_token)
  end

  test "a replacement token invalidates the previous link" do
    replacement = @user.issue_email_confirmation!(@user.email)

    get update_email_confirmations_path(token: @token)

    assert_redirected_to root_path
    refute_predicate @user.reload, :email_confirmed?

    get update_email_confirmations_path(token: replacement)

    assert_response :success
  end

  test "submitting an older confirmation page does not confirm a different target" do
    other = create(:user, :unconfirmed)
    other_token = other.issue_email_confirmation!(other.email)
    @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)

    get update_email_confirmations_path(token: @token)
    first_form_confirmation = css_select("form[action='#{confirm_email_confirmations_path}'] input[name=confirmation]").sole[:value]
    get update_email_confirmations_path(token: other_token)

    post confirm_email_confirmations_path, params: { confirmation: first_form_confirmation }

    assert_redirected_to root_path
    assert_equal I18n.t("email_confirmations.update.token_failure"), flash[:alert]
    refute_predicate @user.reload, :email_confirmed?
    refute_predicate other.reload, :email_confirmed?
    assert @user.valid_email_confirmation_token?(@token)
    assert other.valid_email_confirmation_token?(other_token)
    assert_nil session[:mfa_user]
  end

  test "the confirmation page binding is carried through MFA and rejected when stale" do
    @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
    get update_email_confirmations_path(token: @token)
    confirmation = css_select("input[name=confirmation]").sole[:value]

    post confirm_email_confirmations_path, params: { confirmation: }

    assert_response :success
    assert_select "form[action=?]", otp_update_email_confirmations_url(confirmation:)

    post otp_update_email_confirmations_path, params: { confirmation: "stale", otp: ROTP::TOTP.new(@user.totp_seed).now }

    assert_redirected_to root_path
    refute_predicate @user.reload, :email_confirmed?
  end

  test "an invalid confirmation link does not clear a same-user sign-in MFA challenge" do
    @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
    get update_email_confirmations_path(token: @token)
    post session_path(session: { who: @user.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })

    assert_equal @user.id, session[:mfa_user]
    mfa_state = session.to_hash.slice("mfa_user", "mfa_expires_at", "mfa_login_started_at", "webauthn_authentication")

    get update_email_confirmations_path(token: "invalid")

    assert_redirected_to root_path
    assert_equal mfa_state, session.to_hash.slice("mfa_user", "mfa_expires_at", "mfa_login_started_at", "webauthn_authentication")
  end

  test "an expired token is denied without changing account state" do
    @user.update_column(:email_confirmation_token_expires_at, 1.second.ago)

    get update_email_confirmations_path(token: @token)

    assert_redirected_to root_path
    refute_predicate @user.reload, :email_confirmed?
    refute_nil @user.email_confirmation_token_digest
  end

  test "email change is completed only by POST and clears all authority" do
    user = create(:user, email: "old@rubygems-test.org")
    user.update!(unconfirmed_email: "new@rubygems-test.org")
    token = user.issue_email_confirmation!(user.unconfirmed_email)

    get update_email_confirmations_path(token:)

    assert_response :success
    assert_select "[data-testid=email-confirmation-target]", text: "n**@r************.org"
    assert_select "p", text: I18n.t("email_confirmations.update.new_email_label")
    refute_includes response.body, "new@rubygems-test.org"
    assert_equal "old@rubygems-test.org", user.reload.email
    assert_equal "new@rubygems-test.org", user.unconfirmed_email

    post confirm_email_confirmations_path, params: { confirmation: session[:email_confirmation_id] }

    assert_redirected_to sign_in_path
    assert_equal "new@rubygems-test.org", user.reload.email
    assert_nil user.unconfirmed_email
    assert_nil user.email_confirmation_token_digest
    assert_nil user.email_confirmation_email
  end

  test "changing the pending target invalidates a previously issued token" do
    user = create(:user)
    user.update!(unconfirmed_email: "first@rubygems-test.org")
    token = user.issue_email_confirmation!(user.unconfirmed_email)

    user.update!(unconfirmed_email: "second@rubygems-test.org")
    get update_email_confirmations_path(token:)

    assert_redirected_to root_path
    assert_equal "second@rubygems-test.org", user.reload.unconfirmed_email
    assert_nil user.email_confirmation_token_digest
  end

  test "MFA confirmation requires a valid OTP before consuming the email token" do
    @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
    begin_email_confirmation

    post confirm_email_confirmations_path, params: { confirmation: session[:email_confirmation_id] }

    assert_response :success
    assert_select "h1", text: /Multi-factor authentication/
    refute_predicate @user.reload, :email_confirmed?
    assert @user.valid_email_confirmation_token?(@token)

    post otp_update_email_confirmations_path, params: { confirmation: session[:email_confirmation_id], otp: "incorrect" }

    assert_response :unauthorized
    refute_predicate @user.reload, :email_confirmed?
    assert @user.valid_email_confirmation_token?(@token)

    post otp_update_email_confirmations_path, params: { confirmation: session[:email_confirmation_id], otp: ROTP::TOTP.new(@user.totp_seed).now }

    assert_redirected_to sign_in_path
    assert_predicate @user.reload, :email_confirmed?
    assert_nil @user.email_confirmation_token_digest
  end

  test "the confirmation MFA challenge cannot be used to sign in" do
    user = create(:user, email: "old@rubygems-test.org")
    user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
    user.update!(unconfirmed_email: "new@rubygems-test.org")
    token = user.issue_email_confirmation!(user.unconfirmed_email)
    get update_email_confirmations_path(token:)
    post confirm_email_confirmations_path, params: { confirmation: session[:email_confirmation_id] }

    assert_response :success

    assert_no_difference -> { user.events.where(tag: Events::UserEvent::LOGIN_SUCCESS).count } do
      post otp_create_session_path, params: { otp: ROTP::TOTP.new(user.totp_seed).now }
    end

    assert_response :unauthorized
    assert_predicate cookies[:remember_token], :blank?
    assert_equal "old@rubygems-test.org", user.reload.email
    assert user.valid_email_confirmation_token?(token)
  end

  test "token replacement during MFA prevents confirmation" do
    @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
    recovery_code = @user.new_mfa_recovery_codes.first
    recovery_digests = @user.reload.mfa_hashed_recovery_codes

    refute_nil recovery_code
    begin_email_confirmation
    post confirm_email_confirmations_path, params: { confirmation: session[:email_confirmation_id] }
    @user.issue_email_confirmation!(@user.email)

    post otp_update_email_confirmations_path, params: { confirmation: session[:email_confirmation_id], otp: recovery_code }

    assert_redirected_to root_path
    refute_predicate @user.reload, :email_confirmed?
    assert_equal recovery_digests, @user.mfa_hashed_recovery_codes
  end

  test "token expiry during MFA prevents confirmation" do
    @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
    begin_email_confirmation
    post confirm_email_confirmations_path, params: { confirmation: session[:email_confirmation_id] }
    @user.update_column(:email_confirmation_token_expires_at, 1.second.ago)

    post otp_update_email_confirmations_path, params: { confirmation: session[:email_confirmation_id], otp: ROTP::TOTP.new(@user.totp_seed).now }

    assert_redirected_to root_path
    refute_predicate @user.reload, :email_confirmed?
    refute_nil @user.email_confirmation_token_digest
  end

  test "invalid CSRF is rejected without changing or consuming confirmation authority" do
    original_allow_forgery_protection = ActionController::Base.allow_forgery_protection
    begin_email_confirmation
    ActionController::Base.allow_forgery_protection = true

    post confirm_email_confirmations_path, params: { confirmation: session[:email_confirmation_id] }

    assert_response :forbidden
    refute_predicate @user.reload, :email_confirmed?
    assert @user.valid_email_confirmation_token?(@token)
    assert_email_confirmation_response_headers
  ensure
    ActionController::Base.allow_forgery_protection = original_allow_forgery_protection
  end

  test "public resend cannot rotate or send a pending email-change token" do
    user = create(:user, email: "old@rubygems-test.org")
    user.update!(unconfirmed_email: "new@rubygems-test.org")
    token = user.issue_email_confirmation!(user.unconfirmed_email)
    digest = user.email_confirmation_token_digest

    assert_no_enqueued_emails do
      post email_confirmations_path, params: { email_confirmation: { email: user.email } }
    end

    assert_redirected_to root_path
    assert_equal digest, user.reload.email_confirmation_token_digest
    assert user.valid_email_confirmation_token?(token)
  end

  test "authenticated resend replaces a pending email-change token" do
    user = create(:user)
    user.update!(unconfirmed_email: "new@rubygems-test.org")
    user.issue_email_confirmation!(user.unconfirmed_email)
    old_digest = user.email_confirmation_token_digest
    post session_path(session: { who: user.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })

    assert_enqueued_email_with Mailer, :email_reset, args: [user, user.unconfirmed_email] do
      patch unconfirmed_email_confirmations_path
    end

    assert_redirected_to edit_profile_path
    assert_nil user.reload.email_confirmation_token_digest
    refute_equal old_digest, user.email_confirmation_token_digest
  end

  private

  def begin_email_confirmation
    get update_email_confirmations_path(token: @token)

    assert_response :success
  end

  def assert_email_confirmation_response_headers
    assert_equal "private, no-store", response.headers["Cache-Control"]
    assert_equal "max-age=0", response.headers["Surrogate-Control"]
    assert_equal "no-referrer", response.headers["Referrer-Policy"]
  end

  def assert_other_user_still_signed_in(other, remember_token)
    assert_equal remember_token, other.reload.remember_token
    assert_predicate cookies[:remember_token], :present?

    get dashboard_path

    assert_response :success
  end
end
