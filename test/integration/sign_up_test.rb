require 'test_helper'

class SignUpTest < SystemTest
  test "sign up" do
    visit sign_up_path

    fill_in "Email", with: "email@person.com"
    fill_in "Handle", with: "nick"
    fill_in "Password", with: "password"
    click_button "Sign up"

    assert page.has_content? "Sign out"
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
    fill_in "Handle", with: "thisusernameiswaytoolongseriouslywaytoolong"
    fill_in "Password", with: "password"
    click_button "Sign up"

    assert page.has_content? "error prohibited"
  end

  test "sign up with someone else's handle" do
    create(:user, handle: "nick")
    visit sign_up_path

    fill_in "Email", with: "email@person.com"
    fill_in "Handle", with: "nick"
    fill_in "Password", with: "password"
    click_button "Sign up"

    assert page.has_content? "error prohibited"
  end
end
