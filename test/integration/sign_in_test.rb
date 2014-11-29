require 'test_helper'

class SignInTest < ActionDispatch::IntegrationTest
  setup do
    create(:user, email: "nick@example.com", password: "secret123")
  end

  test "signing in" do
    post session_path, {session: {who: "nick@example.com", password: "secret123"}}

    assert_response :redirect
    assert_redirected_to "/dashboard"
  end

  test "signing in with wrong password" do
    post session_path, {session: {who: "nick@example.com", password: "secret321"}}

    assert_response :unauthorized
  end
end
