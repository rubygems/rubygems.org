require 'test_helper'

class ApiKeyResetTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, email: "nick@example.com", api_key: "secret123")
    cookies[:remember_token] = @user.remember_token
  end

  test "user sees key on profile" do
    get edit_profile_path

    assert_response :success
    assert_match @user.api_key, response.body
  end

  test "user resets api key" do
    put reset_api_v1_api_key_path
    assert_response :redirect

    get edit_profile_path

    assert_response :success
    assert_match @user.reload.api_key, response.body
  end
end
