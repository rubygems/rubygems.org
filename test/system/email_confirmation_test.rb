# frozen_string_literal: true

require "application_system_test_case"
require "helpers/email_helpers"

class EmailConfirmationTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  setup do
    @user = create(:user, email_confirmed: false)
  end

  def request_confirmation_mail(email)
    visit sign_in_path

    click_link "Didn't receive confirmation mail?"
    fill_in "Email address", with: email
    click_button "Resend Confirmation"

    assert_text "We will email you confirmation link to activate your account if one exists."
  end

  test "requesting confirmation mail does not tell if a user exists" do
    request_confirmation_mail "someone@rubygems-test.org"

    assert_text "We will email you confirmation link to activate your account if one exists."
  end

  test "requesting confirmation mail with email of existing user" do
    request_confirmation_mail @user.email

    link = last_email_link

    refute_nil link
    confirm_email_from(link)

    assert_text "Sign in"
    assert page.has_selector? "#flash_notice", text: "Your email address has been verified"
  end

  test "re-using confirmation link, asks user to double check the link" do
    request_confirmation_mail @user.email

    link = last_email_link
    confirm_email_from(link)

    assert_text "Sign in"
    assert page.has_selector? "#flash_notice", text: "Your email address has been verified"

    clear_browser_cache
    visit link

    assert page.has_selector? "#flash_alert", text: "Please double check the URL or try submitting it again."
  end

  test "requesting multiple confirmation email" do
    request_confirmation_mail @user.email
    replaced_link = last_email_link

    request_confirmation_mail @user.email
    replacement_link = last_email_link

    visit replaced_link

    assert page.has_selector? "#flash_alert", text: "Please double check the URL or try submitting it again."

    confirm_email_from(replacement_link)

    assert_no_enqueued_jobs
    assert_predicate @user.reload, :email_confirmed?
  end

  test "requesting confirmation mail with mfa enabled" do
    @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
    request_confirmation_mail @user.email

    link = last_email_link

    refute_nil link
    visit link
    click_button "Confirm email address"

    fill_in "otp", with: ROTP::TOTP.new(@user.totp_seed).now
    click_button "Authenticate"

    assert_text "Sign in"
    assert page.has_selector? "#flash_notice", text: "Your email address has been verified"
  end

  test "requesting confirmation mail with webauthn enabled" do
    @user.confirm_email!
    create_webauthn_credential
    @user.update!(email_confirmed: false)

    request_confirmation_mail @user.email

    link = last_email_link

    refute_nil link
    visit link
    click_button "Confirm email address"

    assert_text "Multi-factor authentication"
    assert_text "Security Device"

    click_on "Authenticate with security device"

    assert_text "Sign in"
    skip("There's a glitch where the webauthn javascript(?) triggers the next page to render twice, clearing flash.")

    assert page.has_selector? "#flash_notice", text: "Your email address has been verified"
  end

  test "requesting confirmation mail with webauthn enabled using recovery codes" do
    @user.confirm_email!
    create_webauthn_credential
    @user.update!(email_confirmed: false)

    request_confirmation_mail @user.email

    link = last_email_link

    refute_nil link
    visit link
    click_button "Confirm email address"

    assert_text "Multi-factor authentication"
    assert_text "Security Device"

    fill_in "otp", with: @mfa_recovery_codes.first
    click_button "Authenticate"

    assert_text "Sign in"
    assert page.has_selector? "#flash_notice", text: "Your email address has been verified"
  end

  test "requesting confirmation mail with mfa enabled, but mfa session is expired" do
    @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_gem_signin)
    request_confirmation_mail @user.email

    link = last_email_link

    refute_nil link
    visit link
    click_button "Confirm email address"

    fill_in "otp", with: ROTP::TOTP.new(@user.totp_seed).now
    travel 16.minutes do
      click_button "Authenticate"

      assert_text "Your login page session has expired."
    end
  end

  teardown do
    disable_virtual_authenticator
    Capybara.reset_sessions!
  end

  private

  def confirm_email_from(link)
    visit link

    assert_text "Confirm email address"
    click_button "Confirm email address"
  end
end
