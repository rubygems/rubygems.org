require 'test_helper'

class ProfileTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, email: "nick@example.com", password: "secret123", handle: "nick1")
    cookies[:remember_token] = @user.remember_token
  end

  test "changing handle" do
    get profile_path("nick1")
    assert_response :success
    assert page.has_content? "nick1"

    put "profile", user: {handle: "nick2"}
    assert_response :redirect

    get profile_path("nick2")
    assert_response :success
    assert page.has_content? "nick2"
  end

  test "changing to an existing handle" do
    create(:user, email: "nick2@example.com", handle: "nick2")

    put "profile", user: {handle: "nick2"}
    assert_response :success
    assert page.has_content? "Handle has already been taken"
  end

  test "changing email allows signing in with new email" do
    put "profile", user: {email: "nick2@example.com"}
    assert_response :redirect

    delete sign_out_path
    assert_response :redirect
    assert_nil cookies[:remember_token]

    post session_path, session: {who: "nick2@example.com", password: "secret123"}
    assert_response :redirect

    get root_path
    assert page.has_content?("Sign out")
  end

  test "disabling email on profile" do
    get profile_path("nick1")
    assert_response :success
    assert page.has_content? "Email Me"

    put "profile", user: {hide_email: true}
    assert_response :redirect

    get profile_path("nick1")
    assert_response :success
    assert ! page.has_content?("Email Me")
  end
end
