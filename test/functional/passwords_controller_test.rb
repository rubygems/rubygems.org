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
        page.assert_text("Reset password")
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
        @controller.session[:mfa_expires_at] = 15.minutes.from_now.to_s
      end

      should respond_with :success

      should "display otp form" do
        page.assert_text("Multi-factor authentication")
      end
    end
  end

  context "on POST to mfa_edit" do
    setup do
      @user = create(:user)
      @user.forgot_password!
    end

    context "with mfa enabled" do
      setup { @user.enable_totp!(ROTP::Base32.random_base32, :ui_only) }

      context "when OTP is correct" do
        setup do
          get :edit, params: { token: @user.confirmation_token, user_id: @user.id }
          post :mfa_edit, params: { user_id: @user.id, token: @user.confirmation_token, otp: ROTP::TOTP.new(@user.mfa_seed).now }
        end

        should respond_with :success

        should "display edit form" do
          page.assert_text("Reset password")
        end
        should "clear mfa_expires_at" do
          assert_nil @controller.session[:mfa_expires_at]
        end
      end

      context "when OTP is incorrect" do
        setup do
          get :edit, params: { token: @user.confirmation_token, user_id: @user.id }
          post :mfa_edit, params: { user_id: @user.id, token: @user.confirmation_token, otp: "eatthis" }
        end

        should respond_with :unauthorized

        should "alert about otp being incorrect" do
          assert_equal "Your OTP code is incorrect.", flash[:alert]
        end
      end

      context "when the OTP session is expired" do
        setup do
          get :edit, params: { token: @user.confirmation_token, user_id: @user.id }
          travel 16.minutes do
            post :mfa_edit, params: { user_id: @user.id, token: @user.confirmation_token, otp: ROTP::TOTP.new(@user.mfa_seed).now }
          end
        end

        should set_flash.now[:alert]
        should respond_with :unauthorized

        should "clear mfa_expires_at" do
          assert_nil @controller.session[:mfa_expires_at]
        end

        should "render sign in page" do
          page.assert_text "Sign in"
        end

        should "not sign in the user" do
          refute_predicate @controller.request.env[:clearance], :signed_in?
        end
      end
    end
  end

  context "on POST to webauthn_edit" do
    setup do
      @user = create(:user)
      @webauthn_credential = create(:webauthn_credential, user: @user)
      get :edit, params: { token: @user.confirmation_token, user_id: @user.id }
      @origin = "http://localhost:3000"
      @rp_id = URI.parse(@origin).host
      @client = WebAuthn::FakeClient.new(@origin, encoding: false)
    end

    context "with webauthn enabled" do
      setup do
        @challenge = session[:webauthn_authentication]["challenge"]
        WebauthnHelpers.create_credential(
          webauthn_credential: @webauthn_credential,
          client: @client
        )
        post(
          :webauthn_edit,
          params: {
            user_id: @user.id,
            token: @user.confirmation_token,
            credentials:
            WebauthnHelpers.get_result(
              client: @client,
              challenge: @challenge
            )
          }
        )
      end

      should respond_with :success

      should "display edit form" do
        page.assert_text("Reset password")
      end

      should "clear mfa_expires_at" do
        assert_nil @controller.session[:mfa_expires_at]
      end
    end

    context "when not providing credentials" do
      setup do
        post :webauthn_edit, params: { user_id: @user.id, token: @user.confirmation_token }, format: :html
      end

      should respond_with :unauthorized

      should "set flash notice" do
        assert_equal "Credentials required", flash[:alert]
      end
    end

    context "when providing wrong credential" do
      setup do
        @wrong_challenge = SecureRandom.hex
        WebauthnHelpers.create_credential(
          webauthn_credential: @webauthn_credential,
          client: @client
        )
        post(
          :webauthn_edit,
          params: {
            user_id: @user.id,
            token: @user.confirmation_token,
            credentials:
            WebauthnHelpers.get_result(
              client: @client,
              challenge: @wrong_challenge
            )
          }
        )
      end

      should respond_with :unauthorized

      should "set flash notice" do
        assert_equal "WebAuthn::ChallengeVerificationError", flash[:alert]
      end
      should "still have the webauthn form url" do
        assert_not_nil page.find(".js-webauthn-session--form")[:action]
      end
    end

    context "when webauthn session is expired" do
      setup do
        @challenge = session[:webauthn_authentication]["challenge"]
        WebauthnHelpers.create_credential(
          webauthn_credential: @webauthn_credential,
          client: @client
        )
        travel 16.minutes do
          post(
            :webauthn_edit,
            params: {
              user_id: @user.id,
              token: @user.confirmation_token,
              credentials:
              WebauthnHelpers.get_result(
                client: @client,
                challenge: @challenge
              )
            }
          )
        end
      end

      should respond_with :unauthorized
      should set_flash.now[:alert]

      should "clear mfa_expires_at" do
        assert_nil @controller.session[:mfa_expires_at]
      end

      should "render sign in page" do
        page.assert_text "Sign in"
      end

      should "not sign in the user" do
        refute_predicate @controller.request.env[:clearance], :signed_in?
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
