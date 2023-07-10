require "test_helper"
require "helpers/email_helpers"

class EmailConfirmationTest < SystemTest
  include ActiveJob::TestHelper

  setup do
    @user = create(:user)
  end

  def request_confirmation_mail(email)
    visit sign_in_path

    click_link "Didn't receive confirmation mail?"
    fill_in "Email address", with: email
    click_button "Resend Confirmation"
  end

  test "requesting confirmation mail does not tell if a user exists" do
    request_confirmation_mail "someone@example.com"

    assert page.has_content? "We will email you confirmation link to activate your account if one exists."
  end

  test "requesting confirmation mail with email of existing user" do
    request_confirmation_mail @user.email

    link = last_email_link

    assert_not_nil link
    visit link

    assert page.has_content? "Sign out"
    assert page.has_selector? "#flash_notice", text: "Your email address has been verified"
  end

  test "re-using confirmation link does not sign in user" do
    request_confirmation_mail @user.email

    link = last_email_link
    visit link
    click_link "Sign out"

    visit link

    assert page.has_content? "Sign in"
    assert page.has_selector? "#flash_alert", text: "Please double check the URL or try submitting it again."
  end

  test "requesting multiple confirmation email" do
    perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
      request_confirmation_mail @user.email
    end
    request_confirmation_mail @user.email

    performed = 0
    perform_enqueued_jobs only: ->(job) { job.is_a?(ActionMailer::MailDeliveryJob) && (performed += 1) == 1 }
    link = confirmation_link
    visit link

    perform_enqueued_jobs only: ActionMailer::MailDeliveryJob

    assert_no_enqueued_jobs
  end

  test "requesting confirmation mail with mfa enabled" do
    @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
    request_confirmation_mail @user.email

    link = last_email_link

    assert_not_nil link
    visit link

    fill_in "otp", with: ROTP::TOTP.new(@user.totp_seed).now
    click_button "Authenticate"

    assert page.has_content? "Sign out"
  end

  test "requesting confirmation mail with webauthn enabled" do
    create_webauthn_credential

    request_confirmation_mail @user.email

    link = last_email_link

    assert_not_nil link
    visit link

    assert page.has_content? "Multi-factor authentication"
    assert page.has_content? "Security Device"

    WebAuthn::AuthenticatorAssertionResponse.any_instance.stubs(:verify).returns true

    click_on "Authenticate with security device"

    find(:css, ".header__popup-link").click

    assert page.has_content?("SIGN OUT")
  end

  test "requesting confirmation mail with webauthn enabled using recovery codes" do
    create_webauthn_credential

    request_confirmation_mail @user.email

    link = last_email_link

    assert_not_nil link
    visit link

    assert page.has_content? "Multi-factor authentication"
    assert page.has_content? "Security Device"

    fill_in "otp", with: @user.mfa_recovery_codes.first
    click_button "Authenticate"

    find(:css, ".header__popup-link").click

    assert page.has_content?("SIGN OUT")
  end

  test "requesting confirmation mail with mfa enabled, but mfa session is expired" do
    @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_gem_signin)
    request_confirmation_mail @user.email

    link = last_email_link

    assert_not_nil link
    visit link

    fill_in "otp", with: ROTP::TOTP.new(@user.totp_seed).now
    travel 16.minutes do
      click_button "Authenticate"

      assert page.has_content? "Your login page session has expired."
    end
  end

  teardown do
    @authenticator&.remove!
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end
end
