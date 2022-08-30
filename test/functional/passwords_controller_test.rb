require "test_helper"

class PasswordsControllerTest < ActionController::TestCase
  context "on POST to create" do
    context "when missing email" do
      should "alerts about missing email" do
        post :create
        assert_equal "Email can't be blank.", flash[:alert]
      end
    end

    context "with valid params" do
      setup do
        @user = create(:user)
        get :create, params: { password: { email: @user.email } }
      end

      should "set a valid confirmation_token" do
        assert_predicate @user, :valid_confirmation_token?
      end
    end
  end

  context "on GET to edit" do
    setup do
      @user = create(:user)
      @user.forgot_password!
    end

    context "with valid confirmation_token" do
      setup do
        get :edit, params: { token: @user.confirmation_token, user_id: @user.id }
      end

      should respond_with :success
      should "display edit form" do
        assert page.has_content?("Reset password")
      end
    end

    context "with expired confirmation_token" do
      setup do
        @user.update_attribute(:token_expires_at, 1.minute.ago)
        get :edit, params: { token: @user.confirmation_token, user_id: @user.id }
      end

      should redirect_to("the home page") { root_path }
      should "warn about invalid url" do
        assert_equal "Please double check the URL or try submitting it again.", flash[:alert]
      end
    end

    context "with mfa enabled" do
      setup do
        @user.mfa_ui_only!
        get :edit, params: { token: @user.confirmation_token, user_id: @user.id }
      end

      should respond_with :success
      should "display otp form" do
        assert page.has_content?("Multi-factor authentication")
      end
    end
  end

  context "on POST to mfa_edit" do
    setup do
      @user = create(:user)
      @user.forgot_password!
    end

    context "with mfa enabled" do
      setup { @user.enable_mfa!(ROTP::Base32.random_base32, :ui_only) }

      context "when OTP is correct" do
        setup do
          post :mfa_edit, params: { user_id: @user.id, token: @user.confirmation_token, otp: ROTP::TOTP.new(@user.mfa_seed).now }
        end

        should respond_with :success
        should "display edit form" do
          assert page.has_content?("Reset password")
        end
      end

      context "when OTP is incorrect" do
        setup do
          post :mfa_edit, params: { user_id: @user.id, token: @user.confirmation_token, otp: "eatthis" }
        end

        should respond_with :unauthorized
        should "alert about otp being incorrect" do
          assert_equal "Your OTP code is incorrect.", flash[:alert]
        end
      end
    end
  end

  context "on PUT to update" do
    setup do
      @user = create(:user)
      @api_key = @user.api_key
      @new_api_key = create(:api_key, user: @user)
      @old_encrypted_password = @user.encrypted_password
    end

    context "with reset_api_key and invalid password" do
      setup do
        put :update, params: {
          user_id: @user.id,
          token: @user.confirmation_token,
          password_reset: { reset_api_key: "true", password: "pass" }
        }
      end

      should respond_with :success
      should "not change api_key" do
        assert_equal(@user.reload.api_key, @api_key)
      end
      should "not change password" do
        assert_equal(@user.reload.encrypted_password, @old_encrypted_password)
      end
    end

    context "without reset_api_key and valid password" do
      setup do
        put :update, params: {
          user_id: @user.id,
          token: @user.confirmation_token,
          password_reset: { password: PasswordHelpers::SECURE_TEST_PASSWORD }
        }
      end

      should respond_with :found
      should "not change api_key" do
        assert_equal(@user.reload.api_key, @api_key)
      end
      should "change password" do
        refute_equal(@user.reload.encrypted_password, @old_encrypted_password)
      end
    end

    context "with reset_api_key false and valid password" do
      setup do
        put :update, params: {
          user_id: @user.id,
          token: @user.confirmation_token,
          password_reset: { reset_api_key: "false", password: PasswordHelpers::SECURE_TEST_PASSWORD }
        }
      end

      should respond_with :found
      should "not change api_key" do
        assert_equal(@user.reload.api_key, @api_key)
      end
      should "change password" do
        refute_equal(@user.reload.encrypted_password, @old_encrypted_password)
      end
    end

    context "with reset_api_key and valid password" do
      setup do
        put :update, params: {
          user_id: @user.id,
          token: @user.confirmation_token,
          password_reset: { reset_api_key: "true", password: PasswordHelpers::SECURE_TEST_PASSWORD }
        }
      end

      should respond_with :found
      should "change api_key" do
        refute_equal(@user.reload.api_key, @api_key)
      end
      should "change password" do
        refute_equal(@user.reload.encrypted_password, @old_encrypted_password)
      end
      should "not delete new api key" do
        refute_predicate @new_api_key.reload, :destroyed?
        refute_empty @user.reload.api_keys
      end
    end

    context "with reset_api_key and reset_api_keys and valid password" do
      setup do
        put :update, params: {
          user_id: @user.id,
          token: @user.confirmation_token,
          password_reset: { reset_api_key: "true", reset_api_keys: "true", password: PasswordHelpers::SECURE_TEST_PASSWORD }
        }
      end

      should respond_with :found
      should "change api_key" do
        refute_equal(@user.reload.api_key, @api_key)
      end
      should "change password" do
        refute_equal(@user.reload.encrypted_password, @old_encrypted_password)
      end
      should "delete new api key" do
        assert_empty @user.reload.api_keys
      end
    end
  end
end
