require 'test_helper'

class SessionTest < ActionDispatch::IntegrationTest
  def retrive_authenticity_token
    get edit_profile_path
    request.session[:_csrf_token]
  end

  setup do
    create(:user, handle: "johndoe", password: "chunkybacon")
    post session_path(session: { who: "johndoe", password: "chunkybacon" })
    ActionController::Base.allow_forgery_protection = true # default is false
    @last_session_token = retrive_authenticity_token
    delete log_out_path(authenticity_token: @last_session_token)
  end

  teardown do
    ActionController::Base.allow_forgery_protection = false
  end

  test "authenticity_token of logged out user is invalid" do
    assert_raise ActionController::InvalidAuthenticityToken do
      post session_path(
        session: { who: "johndoe", password: "chunkybacon" },
        authenticity_token: @last_session_token
      )
    end

    refute_equal request.session[:_csrf_token], @last_session_token
  end

  test "authenticity_token of previous user session is invalid in another session" do
    create(:user, handle: "bob", password: "lovesunicorns")
    get sign_in_path
    post session_path(
      session: { who: "bob", password: "lovesunicorns" },
      authenticity_token: request.session[:_csrf_token]
    )

    assert_raise ActionController::InvalidAuthenticityToken do
      patch "/profile", user: { handle: "alice" }, authenticity_token: @last_session_token
    end

    refute_equal request.session[:_csrf_token], @last_session_token
  end
end
