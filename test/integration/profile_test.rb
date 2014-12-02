require 'test_helper'

class ProfileTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, email: "nick@example.com", handle: "nick1")
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
