require "application_system_test_case"

class ProfileTest < ApplicationSystemTestCase
  setup do
    @user = create(:user, email: "nick@example.com", password: PasswordHelpers::SECURE_TEST_PASSWORD, handle: "nick1", mail_fails: 1)
  end

  def sign_in
    visit sign_in_path
    fill_in "Email or Username", with: @user.reload.email
    fill_in "Password", with: @user.password
    click_button "Sign in"
  end

  test "adding X(formerly Twitter) username without filling in your password" do
    twitter_username = "nick1twitter"

    sign_in
    visit profile_path("nick1")

    click_link "Edit Profile"
    fill_in "user_twitter_username", with: twitter_username

    assert_equal twitter_username, page.find_by_id("user_twitter_username").value

    click_button "Update"

    # Verify that the newly added Twitter username is still on the form so that the user does not need to re-enter it
    assert_equal twitter_username, page.find_by_id("user_twitter_username").value

    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Update"

    assert page.has_content? "Your profile was updated."
    assert_equal twitter_username, page.find_by_id("user_twitter_username").value
  end
end
