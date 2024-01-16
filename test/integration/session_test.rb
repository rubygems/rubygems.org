require "test_helper"

class SessionTest < ActionDispatch::IntegrationTest
  def retrive_authenticity_token(path)
    get path

    assert_response :success
    request.session[:_csrf_token]
  end

  setup do
    create(:user, handle: "johndoe", password: PasswordHelpers::SECURE_TEST_PASSWORD)
    @last_session_token = retrive_authenticity_token sign_in_path
    post session_path(session: { who: "johndoe", password: PasswordHelpers::SECURE_TEST_PASSWORD })
    ActionController::Base.allow_forgery_protection = true # default is false in test env
  end

  teardown do
    ActionController::Base.allow_forgery_protection = false
  end

  test "authenticity_token of guest session should be invalid in authenticated session" do
    post session_path(
      session: { who: "johndoe", password: PasswordHelpers::SECURE_TEST_PASSWORD },
      authenticity_token: @last_session_token
    )

    assert_response :forbidden
    refute_equal request.session[:_csrf_token], @last_session_token
  end

  test "authenticity_token of previous user session is invalid in another session" do
    @last_session_token = retrive_authenticity_token edit_profile_path
    delete sign_out_path(authenticity_token: request.session[:_csrf_token])

    assert_response :redirect
    assert_redirected_to sign_in_path

    create(:user, handle: "bob", password: PasswordHelpers::SECURE_TEST_PASSWORD)
    post session_path(
      session: { who: "bob", password: PasswordHelpers::SECURE_TEST_PASSWORD },
      authenticity_token: request.session[:_csrf_token]
    )

    assert_response :redirect
    assert_redirected_to dashboard_path

    patch "/profile", params: { user: { handle: "alice" }, authenticity_token: @last_session_token }

    assert_response :forbidden
    refute_equal request.session[:_csrf_token], @last_session_token
  end
end
