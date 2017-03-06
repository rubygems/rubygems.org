require 'test_helper'

class SignInTest < SystemTest
  setup do
    create(:user, email: "nick@example.com", password: "secret12345")
  end

  test "signing in" do
    visit sign_in_path
    fill_in "Email or Username", with: "nick@example.com"
    fill_in "Password", with: "secret12345"
    click_button "Sign in"

    assert page.has_content? "Sign out"
  end

  test "signing in with uppercase email" do
    visit sign_in_path
    fill_in "Email or Username", with: "Nick@example.com"
    fill_in "Password", with: "secret12345"
    click_button "Sign in"

    assert page.has_content? "Sign out"
  end

  test "signing in with wrong password" do
    visit sign_in_path
    fill_in "Email or Username", with: "nick@example.com"
    fill_in "Password", with: "wordcrimes12345"
    click_button "Sign in"

    assert page.has_content? "Sign in"
    assert page.has_content? "Bad email or password"
  end

  test "signing in with wrong email" do
    visit sign_in_path
    fill_in "Email or Username", with: "someone@example.com"
    fill_in "Password", with: "secret12345"
    click_button "Sign in"

    assert page.has_content? "Sign in"
    assert page.has_content? "Bad email or password"
  end

  test "signing in with unconfirmed email" do
    visit sign_up_path

    fill_in "Email", with: "email@person.com"
    fill_in "Username", with: "nick"
    fill_in "Password", with: "secretpassword"
    click_button "Sign up"

    visit sign_in_path
    fill_in "Email or Username", with: "email@person.com"
    fill_in "Password", with: "secretpassword"
    click_button "Sign in"

    assert page.has_content? "Sign in"
    assert page.has_content? "Please confirm your email address with the link sent to you email."
  end

  test "signing out" do
    visit sign_in_path
    fill_in "Email or Username", with: "nick@example.com"
    fill_in "Password", with: "secret12345"
    click_button "Sign in"

    click_link "Sign out"

    assert page.has_content? "Sign in"
  end
end
