require "test_helper"

class PasswordsControllerTest < ActionController::TestCase
  context "on POST to create" do
    context "when missing a parameter" do
      should "raises parameter missing" do
        post :create
        assert_response :bad_request
        assert page.has_content?("Request is missing param 'password'")
      end
    end

    context "with valid params" do
      setup do
        @user = create(:user)
        get :create, params: { password: { email: @user.email } }
      end

      should "set a valid confirmation_token" do
        assert @user.valid_confirmation_token?
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
        assert_equal flash[:alert], "Please double check the URL or try submitting it again."
      end
    end

    context "with mfa enabled" do
      setup do
        @user.mfa_ui_only!
        get :edit, params: { token: @user.confirmation_token, user_id: @user.id }
      end

      should respond_with :success
      should "display otp form" do
        assert page.has_content?("Multifactor authentication")
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
          assert_equal flash[:alert], "Your OTP code is incorrect."
        end
      end
    end
  end

  context "on PUT to update" do
    setup do
      @user = create(:user)
      @api_key = @user.api_key
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
        assert(@user.reload.api_key == @api_key)
      end
      should "not change password" do
        assert(@user.reload.encrypted_password == @old_encrypted_password)
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
        assert(@user.reload.api_key == @api_key)
      end
      should "change password" do
        assert(@user.reload.encrypted_password != @old_encrypted_password)
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
        assert(@user.reload.api_key == @api_key)
      end
      should "change password" do
        assert(@user.reload.encrypted_password != @old_encrypted_password)
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
        assert(@user.reload.api_key != @api_key)
      end
      should "change password" do
        assert(@user.reload.encrypted_password != @old_encrypted_password)
      end
    end
  end

  context "on GET to show" do
    setup do
      rubygem = create(:rubygem)
      session[:redirect_uri] = rubygem_owners_url(rubygem)
    end

    context "when signed in" do
      setup do
        user = create(:user)
        sign_in_as(user)
        get :show, params: { user_id: user.id }
      end
      should respond_with :success
      should "render password verification form" do
        assert page.has_css? "#verify_password_password"
      end
    end

    context "when not signed in" do
      setup do
        user = create(:user)
        get :show, params: { user_id: user.id }
      end
      should redirect_to("sign in") { sign_in_path }
    end
  end

  context "on POST to verify" do
    setup do
      rubygem = create(:rubygem)
      session[:redirect_uri] = rubygem_owners_url(rubygem)
    end

    context "when signed in" do
      context "on correct password" do
        setup do
          user = create(:user)
          @rubygem = create(:rubygem)
          sign_in_as(user)
          session[:redirect_uri] = rubygem_owners_url(@rubygem)
          post :verify, params: { user_id: user.id, verify_password: { password: PasswordHelpers::SECURE_TEST_PASSWORD } }
        end
        should redirect_to("redirect uri") { rubygem_owners_path(@rubygem) }
      end
      context "on incorrect password" do
        setup do
          @user = create(:user)
          @rubygem = create(:rubygem)
          sign_in_as(@user)
          session[:redirect_uri] = rubygem_owners_url(@rubygem)
          post :verify, params: { user_id: @user.id, verify_password: { password: "wrong password" } }
        end
        should respond_with :unauthorized
        should "show error flash" do
          assert_equal "This request was denied. We could not verify your password.", flash[:alert]
        end
      end
    end

    context "when not signed in" do
      setup do
        user = create(:user)
        post :verify, params: { user_id: user.id, verify_password: { password: PasswordHelpers::SECURE_TEST_PASSWORD } }
      end
      should redirect_to("sign in") { sign_in_path }
    end
  end
end
