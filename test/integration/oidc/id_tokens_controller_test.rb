require "test_helper"

class OIDC::IdTokensControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, remember_token_expires_at: Gemcutter::REMEMBER_FOR.from_now)
    post session_path(session: { who: @user.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })

    @id_token = create(:oidc_id_token, user: @user)
  end

  context "with a verified session" do
    setup do
      post(authenticate_session_path(verify_password: { password: PasswordHelpers::SECURE_TEST_PASSWORD }))
    end

    should "get show" do
      get profile_oidc_id_token_url(@id_token)

      assert_response :success
    end

    should "get index" do
      get profile_oidc_id_tokens_url

      assert_response :success
    end
  end

  context "without a verified session" do
    should "redirect show to verify" do
      get profile_oidc_id_token_url(@id_token)

      assert_response :redirect
      assert_redirected_to verify_session_path
    end

    should "redirect index to verify" do
      get profile_oidc_id_tokens_url

      assert_response :redirect
      assert_redirected_to verify_session_path
    end
  end
end
