require "test_helper"
require "helpers/email_helpers"

class EmailConfirmationTest < SystemTest
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
    request_confirmation_mail @user.email
    request_confirmation_mail @user.email

    link = confirmation_link_from(Delayed::Job.first)
    visit link

    Delayed::Worker.new.work_off
    assert_empty Delayed::Job.all
  end

  test "requesting confirmation mail with mfa enabled" do
    @user.enable_mfa!(ROTP::Base32.random_base32, :ui_only)
    request_confirmation_mail @user.email

    link = last_email_link
    assert_not_nil link
    visit link

    fill_in "otp", with: ROTP::TOTP.new(@user.mfa_seed).now
    click_button "Authenticate"

    assert page.has_content? "Sign out"
  end
end
