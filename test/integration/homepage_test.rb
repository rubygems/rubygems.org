# frozen_string_literal: true

require "test_helper"

class HomepageTest < ActionDispatch::IntegrationTest
  test "anonymous request does not set a session cookie" do
    get root_path

    assert_response :success
    assert_nil response.headers["Set-Cookie"]
  end

  test "anonymous request sets public cache headers" do
    get root_path

    assert_response :success
    assert_includes response.headers["Cache-Control"], "public"
  end

  test "authenticated request sets a session cookie" do
    user = create(:user, remember_token_expires_at: Gemcutter::REMEMBER_FOR.from_now)
    post session_path(session: { who: user.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })

    get root_path

    assert_response :success
    assert_includes response.headers["Set-Cookie"].to_s, "_rubygems_session"
    refute_includes response.headers["Cache-Control"], "public"
  end
end
