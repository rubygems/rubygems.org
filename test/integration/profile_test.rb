require 'test_helper'

class ProfileTest < SystemTest
  setup do
    @user = create(:user, email: "nick@example.com", password: "secret123", handle: "nick1")
  end

  def sign_in
    visit sign_in_path
    fill_in "Email or Handle", with: @user.reload.email
    fill_in "Password", with: @user.password
    click_button "Sign in"
  end

  test "changing handle" do
    sign_in

    visit profile_path("nick1")
    assert page.has_content? "nick1"

    click_link "Edit Profile"
    fill_in "Handle", with: "nick2"
    click_button "Update"

    assert page.has_content? "nick2"
  end

  test "changing to an existing handle" do
    create(:user, email: "nick2@example.com", handle: "nick2")

    sign_in
    visit profile_path("nick1")
    click_link "Edit Profile"

    fill_in "Handle", with: "nick2"
    click_button "Update"

    assert page.has_content? "Handle has already been taken"
  end

  test "changing email allows signing in with new email" do
    sign_in
    visit profile_path("nick1")
    click_link "Edit Profile"

    fill_in "Email address", with: "nick2@example.com"
    click_button "Update"

    click_link "Sign out"

    sign_in
    assert page.has_content? "Sign out"
  end

  test "disabling email on profile" do
    sign_in
    visit profile_path("nick1")
    click_link "Edit Profile"

    check "Hide email in public profile"
    click_button "Update"

    visit profile_path("nick1")
    refute page.has_content?("Email Me")
  end
end
