require "test_helper"

class PasswordResetTest < SystemTest
  include ActiveJob::TestHelper

  def password_reset_link
    body = ActionMailer::Base.deliveries.last.parts[1].body.decoded.to_s
    link = %r{http://localhost/users([^";]*)}.match(body)
    link[0]
  end

  setup do
    @user = create(:user, handle: nil)
  end

  def forgot_password_with(email)
    visit sign_in_path

    click_link "Forgot password?"
    fill_in "Email address", with: email
    perform_enqueued_jobs { click_button "Reset password" }
  end

  test "reset password form does not tell if a user exists" do
    forgot_password_with "someone@example.com"

    assert page.has_content? "instructions for changing your password"
  end

  test "resetting password without handle" do
    forgot_password_with @user.email

    visit password_reset_link
    expected_path = "/users/#{@user.id}/password/edit"
    assert_equal expected_path, page.current_path, "removes confirmation token from url"

    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Save this password"
    assert_equal dashboard_path, page.current_path

    click_link "Sign out"

    visit sign_in_path
    fill_in "Email or Username", with: @user.email
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign in"

    assert page.has_content? "Sign out"
  end

  test "resetting a password with a blank password" do
    forgot_password_with @user.email

    visit password_reset_link

    fill_in "Password", with: ""
    click_button "Save this password"

    assert page.has_content? "Password can't be blank."
    assert page.has_content? "Sign in"
  end

  test "resetting a password when signed in" do
    visit sign_in_path

    fill_in "Email or Username", with: @user.email
    fill_in "Password", with: @user.password
    click_button "Sign in"

    visit edit_settings_path

    click_link "Reset password"

    fill_in "Email address", with: @user.email
    perform_enqueued_jobs { click_button "Reset password" }

    visit password_reset_link

    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Save this password"

    assert @user.reload.authenticated? PasswordHelpers::SECURE_TEST_PASSWORD
  end

  test "restting password when mfa is enabled" do
    @user.enable_mfa!(ROTP::Base32.random_base32, :ui_only)
    forgot_password_with @user.email

    visit password_reset_link

    fill_in "otp", with: ROTP::TOTP.new(@user.mfa_seed).now
    click_button "Authenticate"

    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Save this password"

    assert page.has_content?("Sign out")
  end

  test "resetting password with pending email change" do
    visit sign_in_path

    email = @user.email
    new_email = "hijack@example.com"

    fill_in "Email or Username", with: email
    fill_in "Password", with: @user.password
    click_button "Sign in"

    visit edit_profile_path

    fill_in "Username", with: "username"
    fill_in "Email address", with: new_email
    fill_in "Password", with: @user.password
    perform_enqueued_jobs { click_button "Update" }

    assert_equal new_email, @user.reload.unconfirmed_email

    click_link "Sign out"

    forgot_password_with email

    assert_nil @user.reload.unconfirmed_email

    token = /edit\?token=(.+)$/.match(password_reset_link)[1]
    visit update_email_confirmations_path(token: token)

    assert @user.reload.authenticated? PasswordHelpers::SECURE_TEST_PASSWORD
    assert_equal email, @user.email
  end
end
