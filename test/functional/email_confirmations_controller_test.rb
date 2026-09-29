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

    post confirm_email_confirmations_path

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
    post confirm_email_confirmations_path, params: { authenticity_token: }

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
    assert_equal remember_token, other.reload.remember_token
    refute_predicate @user.reload, :email_confirmed?

    get dashboard_path

    assert_response :success

    post confirm_email_confirmations_path

    assert_redirected_to sign_in_path
    refute_equal remember_token, other.reload.remember_token
    assert_predicate @user.reload, :email_confirmed?
  end

  test "a replacement token invalidates the previous link" do
    replacement = @user.issue_email_confirmation!(@user.email)

    get update_email_confirmations_path(token: @token)

    assert_redirected_to root_path
    refute_predicate @user.reload, :email_confirmed?

    get update_email_confirmations_path(token: replacement)

    assert_response :success
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

    post confirm_email_confirmations_path

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

    post confirm_email_confirmations_path

    assert_response :success
    assert_select "h1", text: /Multi-factor authentication/
    refute_predicate @user.reload, :email_confirmed?
    assert @user.valid_email_confirmation_token?(@token)

    post otp_update_email_confirmations_path, params: { otp: "incorrect" }

    assert_response :unauthorized
    refute_predicate @user.reload, :email_confirmed?
    assert @user.valid_email_confirmation_token?(@token)

    post otp_update_email_confirmations_path, params: { otp: ROTP::TOTP.new(@user.totp_seed).now }

    assert_redirected_to sign_in_path
    assert_predicate @user.reload, :email_confirmed?
    assert_nil @user.email_confirmation_token_digest
  end

  test "token replacement during MFA prevents confirmation" do
    @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
    begin_email_confirmation
    post confirm_email_confirmations_path
    @user.issue_email_confirmation!(@user.email)

    post otp_update_email_confirmations_path, params: { otp: ROTP::TOTP.new(@user.totp_seed).now }

    assert_redirected_to root_path
    refute_predicate @user.reload, :email_confirmed?
  end

  test "token expiry during MFA prevents confirmation" do
    @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
    begin_email_confirmation
    post confirm_email_confirmations_path
    @user.update_column(:email_confirmation_token_expires_at, 1.second.ago)

    post otp_update_email_confirmations_path, params: { otp: ROTP::TOTP.new(@user.totp_seed).now }

    assert_redirected_to root_path
    refute_predicate @user.reload, :email_confirmed?
    refute_nil @user.email_confirmation_token_digest
  end

  test "invalid CSRF is rejected without changing or consuming confirmation authority" do
    original_allow_forgery_protection = ActionController::Base.allow_forgery_protection
    begin_email_confirmation
    ActionController::Base.allow_forgery_protection = true

    post confirm_email_confirmations_path

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
    assert_includes %w[no-store max-age=0], response.headers["Surrogate-Control"]
    assert_equal "no-referrer", response.headers["Referrer-Policy"]
  end
end
