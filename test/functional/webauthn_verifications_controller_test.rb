require "test_helper"

class WebauthnVerificationsControllerTest < ActionController::TestCase
  context "#prompt" do
    context "when given an expired webauthn token" do
      setup do
        @user = create(:user)
        token = create(:webauthn_verification, user: @user, path_token_expires_at: 1.minute.ago).path_token
        get :prompt, params: { webauthn_token: token }
      end

      should "return a 404" do
        assert_response :not_found
      end
    end

    context "when given an invalid webauthn token" do
      setup do
        @user = create(:user)
        get :prompt, params: { webauthn_token: "not_valid1234" }
      end

      should "return a 404" do
        assert_response :not_found
      end
    end

    context "when given a valid webauthn token param" do
      setup do
        @user = create(:user)
        @token = create(:webauthn_verification, user: @user).path_token
      end

      context "with webauthn devices enabled" do
        setup do
          create(:webauthn_credential, user: @user)
          get :prompt, params: { webauthn_token: @token }
        end

        should respond_with :success
        should "set webauthn authentication" do
          assert_equal @user.id, session[:webauthn_authentication]["user"]
          assert_not_nil session[:webauthn_authentication]["challenge"]
        end

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

      context "with no webauthn devices enabled" do
        setup do
          get :prompt, params: { webauthn_token: @token }
        end

        should respond_with :redirect
        should redirect_to("the homepage") { root_url }
        should "display error that user has no webauthn devices enabled" do
          assert_equal "You don't have any security devices enabled", flash[:alert]
        end
      end
    end
  end
end
