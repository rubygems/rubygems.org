require 'test_helper'

class SignUpTest < SystemTest
  test "sign up" do
    visit sign_up_path

    fill_in "Email", with: "email@person.com"
    fill_in "Username", with: "nick"
    fill_in "Password", with: "secretpassword"
    click_button "Sign up"

    assert page.has_selector? '#flash_notice', text: "A confirmation mail has been sent to your email address."
  end

  test "sign up with no handle" do
    visit sign_up_path

    fill_in "Email", with: "email@person.com"
    fill_in "Password", with: "password"
    click_button "Sign up"

    assert page.has_content? "errors prohibited"
  end

  test "sign up with bad handle" do
    visit sign_up_path

    fill_in "Email", with: "email@person.com"
    fill_in "Username", with: "thisusernameiswaytoolongseriouslywaytoolong"
    fill_in "Password", with: "secretpassword"
    click_button "Sign up"

    assert page.has_content? "error prohibited"
  end

  test "sign up with someone else's handle" do
    create(:user, handle: "nick")
    visit sign_up_path

    fill_in "Email", with: "email@person.com"
    fill_in "Username", with: "nick"
    fill_in "Password", with: "secretpassword"
    click_button "Sign up"

    assert page.has_content? "error prohibited"
  end

  test "sign up when sign up is disabled" do
    Clearance.configure { |config| config.allow_sign_up = false }
    Rails.application.reload_routes!

    visit root_path
    refute page.has_content? "Sign up"
    visit sign_up_path
    assert_equal current_path, "/"
    assert page.has_content? "Sign up is temporarily disabled."
  end

  test "email confirmation" do
    visit sign_up_path

    fill_in "Email", with: "email@person.com"
    fill_in "Username", with: "nick"
    fill_in "Password", with: "secretpassword"
    click_button "Sign up"

    link = last_email_link
    assert_not_nil link
    visit link

    assert page.has_content? "Sign out"
    assert page.has_selector? '#flash_notice', text: "Your email address has been verified"
  end

  teardown do
    Clearance.configure { |config| config.allow_sign_up = true }
    Rails.application.reload_routes!
  end
end
