require "test_helper"

class WebauthnVerificationsControllerTest < ActionController::TestCase
  context "#verify" do
    context "when given an expired webauthn token" do
      setup do
        @user = create(:user)
        token = create(:webauthn_verification, user: @user, path_token_expires_at: 1.minute.ago).path_token
        get :verify, params: { webauthn_token: token }
      end

      should "return a 404" do
        assert_response :not_found
      end
    end

    context "when given an invalid webauthn token" do
      setup do
        @user = create(:user)
        get :verify, params: { webauthn_token: "not_valid1234" }
      end

      should "return a 404" do
        assert_response :not_found
      end
    end

    context "when given a valid webauthn token param" do
      setup do
        @user = create(:user)
        create(:webauthn_credential, user: @user)
        token = create(:webauthn_verification, user: @user).path_token
        get :verify, params: { webauthn_token: token }
      end

      should respond_with :success
      should "render the verification page" do
        assert page.has_content?("Authenticate with Security Device")
      end

      should "set the user" do
        assert page.has_content?(@user.name)
      end

      should "provide the verification button" do
        assert page.has_button?("Authenticate")
      end
    end
  end
end
