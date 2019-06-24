require "test_helper"

class PasswordResetTest < SystemTest
  include ActiveJob::TestHelper

  def password_reset_link
    body = ActionMailer::Base.deliveries.last.body.decoded.to_s
    link = %r{http://localhost/users([^";]*)}.match(body)
    link[0]
  end

  setup do
    @user = create(:user, handle: nil)
  end

  # clears session[:password_reset_token] set in edit action
  teardown { reset_session! }

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

    fill_in "Password", with: "secret54321"
    click_button "Save this password"
    assert_equal dashboard_path, page.current_path

    click_link "Sign out"

    visit sign_in_path
    fill_in "Email or Username", with: @user.email
    fill_in "Password", with: "secret54321"
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

    visit profile_path(@user)
    click_link "Edit Profile"

    click_link "Request a new one here."

    fill_in "Email address", with: @user.email
    perform_enqueued_jobs { click_button "Reset password" }

    visit password_reset_link

    fill_in "Password", with: "secret54321"
    click_button "Save this password"

    assert @user.reload.authenticated? "secret54321"
  end

  test "restting password when mfa is enabled" do
    @user.enable_mfa!(ROTP::Base32.random_base32, :ui_only)
    forgot_password_with @user.email

    visit password_reset_link

    fill_in "otp", with: ROTP::TOTP.new(@user.mfa_seed).now
    click_button "Authenticate"

    fill_in "Password", with: "secret3210"
    click_button "Save this password"

    assert page.has_content?("Sign out")
  end
end
