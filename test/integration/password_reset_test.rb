require 'test_helper'

class PasswordResetTest < SystemTest
  setup do
    @user = create(:user, handle: nil)
  end

  def forgot_password_with(email)
    visit sign_in_path

    click_link "Forgot Password?"
    fill_in "Email address", with: email
    click_button "Reset password"
  end

  test "reset password form does not tell if a user exists" do
    forgot_password_with "someone@example.com"

    assert page.has_content? "instructions for changing your password"
  end

  test "resetting password without handle" do
    forgot_password_with @user.email
    body = ActionMailer::Base.deliveries.last.to_s
    link = body.split("\n").find { |line| line =~ /^http/ }
    assert_not_nil link

    visit link
    fill_in "Password", with: "secret54321"
    click_button "Save this password"

    click_link "Sign out"

    visit sign_in_path
    fill_in "Email or Handle", with: @user.email
    fill_in "Password", with: "secret54321"
    click_button "Sign in"

    assert page.has_content? "Sign out"
  end

  test "resetting a password with a blank password" do
    forgot_password_with @user.email

    body = ActionMailer::Base.deliveries.last.to_s
    link = body.split("\n").find { |line| line =~ /^http/ }
    assert_not_nil link

    visit link
    fill_in "Password", with: ""
    click_button "Save this password"

    assert page.has_content? "Password can't be blank."
    assert page.has_content? "Sign in"
  end

  test "resetting a password when signed in" do
    visit sign_in_path

    fill_in "Email or Handle", with: @user.email
    fill_in "Password", with: @user.password
    click_button "Sign in"

    visit profile_path(@user)
    click_link "Edit Profile"

    click_link "Request a new one here."

    fill_in "Email address", with: @user.email
    click_button "Reset password"

    body = ActionMailer::Base.deliveries.last.to_s
    link = body.split("\n").find { |line| line =~ /^http/ }
    visit link

    fill_in "Password", with: "secret321"
    click_button "Save this password"

    assert page.has_content?("Sign out")
  end
end
