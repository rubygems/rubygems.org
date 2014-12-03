require 'test_helper'

class PasswordResetTest < SystemTest
  setup do
    @user = create(:user, handle: nil)
  end

  test "resetting password without handle" do
    visit sign_in_path

    click_link "Forgot Password?"
    fill_in "Email address", with: @user.email
    click_button "Reset password"

    email = ActionMailer::Base.deliveries.last.body.to_s
    link = email.split("\n").find { |line| line =~ /^http/ }

    visit link
    fill_in "Password", with: "secret321"
    click_button "Save this password"

    click_link "Sign out"

    visit sign_in_path
    fill_in "Email or Handle", with: @user.email
    fill_in "Password", with: "secret321"
    click_button "Sign in"

    assert page.has_content? "Sign out"
  end
end
