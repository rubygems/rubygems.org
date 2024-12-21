require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  context "on GET to new" do
    should "display the password reset form" do
      get new_password_path

      assert_response :success
      assert_select "h1", "Change your password"
      assert_select "form[action=?]", password_path do
        assert_select "input[type=email][name=?]", "password[email]"
      end
    end
  end

  context "on POST to create" do
    context "when missing email" do
      should "alerts about missing email" do
        post password_path

        assert_equal "Email can't be blank.", flash[:alert]
      end
    end

    context "with valid params" do
      should "set a valid confirmation_token" do
        @user = create(:user)

        assert_nil @user.confirmation_token

        post password_path, params: { password: { email: @user.email } }

        assert_select "p", "You will receive an email within the next few minutes. It contains instructions for changing your password."
        assert_not_nil @user.reload.confirmation_token
        assert_predicate @user, :valid_confirmation_token?
      end
    end
  end

  context "on GET to edit" do
    setup do
      @user = create(:user)
      @user.forgot_password!
    end

    context "with incorrect token" do
      should "redirect to the sign in page" do
        get edit_password_path, params: { token: "invalidtoken" }

        assert_redirected_to sign_in_path
        assert_equal "Please double check the URL or try submitting a new password reset.", flash[:alert]
        refute_signed_in
      end
    end

    context "with valid confirmation_token" do
      context "when not signed in" do
        should "presents the password edit form" do
          get edit_password_path, params: { token: @user.confirmation_token }

          assert_response :success
          assert_new_password_form

          assert_nil @user.reload.confirmation_token
          refute_signed_in

          # instruct the browser not to send referrer that contains the token" do
          assert_equal "no-referrer", response.headers["Referrer-Policy"]
        end
      end

      context "when signed in as the user" do
        should "presents the password edit form" do
          get edit_password_path(as: @user), params: { token: @user.confirmation_token }

          assert_response :success
          assert_new_password_form

          assert_nil @user.reload.confirmation_token

          # instruct the browser not to send referrer that contains the token" do
          assert_equal "no-referrer", response.headers["Referrer-Policy"]
        end
      end

      context "when signed in as another user" do
        should "presents the password edit form for the token identified user, signing the other user out" do
          @other_user = create(:user, api_key: "otheruserkey")

          get edit_password_path(as: @other_user), params: { token: @user.confirmation_token }

          assert_response :success
          assert_new_password_form

          refute_signed_in
          assert_nil @user.reload.confirmation_token

          # instruct the browser not to send referrer that contains the token" do
          assert_equal "no-referrer", response.headers["Referrer-Policy"]
        end
      end
    end

    context "with expired confirmation_token" do
      should "redirect to the sign in page" do
        @user.update_attribute(:token_expires_at, 1.minute.ago)
        get edit_password_path, params: { token: @user.confirmation_token }

        assert_redirected_to sign_in_path
        assert_equal I18n.t("passwords.edit.token_failure"), flash[:alert]
        refute_signed_in
      end
    end

    context "with totp enabled" do
      should "display otp form" do
        @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
        get edit_password_path, params: { token: @user.confirmation_token }

        assert_response :success
        assert_otp_form
        refute_signed_in
      end
    end

    context "when user has webauthn credentials but no recovery codes" do
      should "display webauthn prompt only" do
        create(:webauthn_credential, user: @user)
        @user.update!(new_mfa_recovery_codes: nil, mfa_hashed_recovery_codes: [])

        get edit_password_path, params: { token: @user.confirmation_token }

        assert_response :success
        assert_webauthn_form
        refute page.has_content?("Recovery code"), "Recovery code form should not be displayed"
        refute_signed_in
      end
    end

    context "when user has webauthn credentials and recovery codes" do
      should "display webauthn prompt and recovery code prompt" do
        create(:webauthn_credential, user: @user)
        get edit_password_path, params: { token: @user.confirmation_token }

        assert_response :success
        assert_webauthn_form
        assert_select "form[action=?]", otp_edit_password_url(token: @user.confirmation_token) do
          assert_select "input[type=text][autocomplete=off]" # no autocomplete for recovery code only
          assert_select "input[type=submit][value=?]", I18n.t("authenticate")
        end
        assert page.has_content?("Recovery code"), "Expect recovery code form"
        refute_signed_in
      end
    end

    context "when user has webauthn and totp" do
      should "display webauthn and otp prompt" do
        @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
        create(:webauthn_credential, user: @user)

        get edit_password_path, params: { token: @user.confirmation_token }

        assert_response :success
        assert_webauthn_form
        assert_otp_form
        assert page.has_content?(I18n.t("multifactor_auths.prompt.otp_or_recovery")), "Expect OTP or recovery code form"
        refute_signed_in
      end
    end
  end

  context "on POST to otp_edit" do
    setup do
      @user = create(:user)
      @user.forgot_password!
    end

    context "when providing incorrect token" do
      should "redirect to the sign in page" do
        post otp_edit_password_path, params: { token: "badtoken" }

        assert_redirected_to sign_in_path
        assert_equal "Please double check the URL or try submitting a new password reset.", flash[:alert]
        assert_nil session[:mfa_expires_at]
        refute_signed_in
      end
    end

    context "with mfa enabled" do
      setup { @user.enable_totp!(ROTP::Base32.random_base32, :ui_only) }

      context "when OTP is correct" do
        should "display edit form" do
          get edit_password_path, params: { token: @user.confirmation_token }
          post otp_edit_password_path, params: { token: @user.confirmation_token, otp: ROTP::TOTP.new(@user.totp_seed).now }

          assert_response :success
          assert_new_password_form

          refute_signed_in
          assert_nil @user.reload.confirmation_token
          assert_nil session[:mfa_expires_at]
        end
      end

      context "when OTP is incorrect" do
        should "display error message and prompt for MFA again" do
          get edit_password_path, params: { token: @user.confirmation_token }
          post otp_edit_password_path, params: { token: @user.confirmation_token, otp: "wrong" }

          assert_response :unauthorized
          assert_select "#flash_alert", "Your OTP code is incorrect."
          assert_otp_form

          refute_signed_in
        end
      end

      context "when the OTP session is expired" do
        should "redirect to the sign in page" do
          get edit_password_path, params: { token: @user.confirmation_token }
          travel 16.minutes do
            post otp_edit_password_path, params: { token: @user.confirmation_token, otp: ROTP::TOTP.new(@user.totp_seed).now }
          end

          assert_redirected_to sign_in_path
          assert_equal "Your login page session has expired.", flash[:alert]

          assert_nil session[:mfa_expires_at]
          refute_signed_in
        end
      end
    end
  end

  context "on POST to webauthn_edit" do
    setup do
      @user = create(:user)
      @user.forgot_password!
      @webauthn_credential = create(:webauthn_credential, user: @user)

      @origin = WebAuthn.configuration.origin
      @rp_id = URI.parse(@origin).host
      @client = WebAuthn::FakeClient.new(@origin, encoding: false)
    end

    context "with correct webauthn" do
      should "display edit form" do
        get edit_password_path, params: { token: @user.confirmation_token }
        post webauthn_edit_password_path, params: {
          token: @user.confirmation_token, credentials: webauthn_result
        }

        assert_response :success
        assert_new_password_form

        refute_signed_in
        assert_nil @user.reload.confirmation_token
        assert_nil session[:mfa_expires_at]
      end
    end

    context "when providing incorrect confirmation_token" do
      should "redirect to the sign in page" do
        get edit_password_path, params: { token: @user.confirmation_token }
        post webauthn_edit_password_path, params: {
          token: "wrongtoken", credentials: webauthn_result
        }

        assert_redirected_to sign_in_path
        assert_equal "Please double check the URL or try submitting a new password reset.", flash[:alert]

        assert_nil session[:mfa_expires_at]
        refute_signed_in
      end
    end

    context "when not providing credentials" do
      should "display error message and prompt for MFA again" do
        get edit_password_path, params: { token: @user.confirmation_token }
        post webauthn_edit_password_path, params: { token: @user.confirmation_token }

        assert_response :unauthorized
        assert_select "#flash_alert", "Credentials required"
        assert_webauthn_form

        refute_signed_in
      end
    end

    context "when providing wrong credential" do
      should "display error message and prompt for MFA again" do
        get edit_password_path, params: { token: @user.confirmation_token }
        wrong_challenge = SecureRandom.hex
        post webauthn_edit_password_path, params: {
          token: @user.confirmation_token, credentials: webauthn_result(wrong_challenge)
        }

        assert_response :unauthorized
        assert_select "#flash_alert", "WebAuthn::ChallengeVerificationError"
        assert_webauthn_form

        refute_signed_in
      end
    end

    context "when webauthn session is expired" do
      should "redirect to the sign in page" do
        get edit_password_path, params: { token: @user.confirmation_token }
        travel 16.minutes do
          post webauthn_edit_password_path, params: {
            token: @user.confirmation_token, credentials: webauthn_result
          }
        end

        assert_redirected_to sign_in_path
        assert_equal "Your login page session has expired.", flash[:alert]
        assert_nil session[:mfa_expires_at]
        refute_signed_in
      end
    end
  end

  context "on PUT to update" do
    setup do
      @user = create(:user)
      @user.forgot_password!
      @api_key = @user.api_key
      @new_api_key = create(:api_key, owner: @user)
      @old_encrypted_password = @user.encrypted_password
    end

    context "when not verified for password reset" do
      should "redirect to the sign in page" do
        put password_path, params: {
          password_reset: { reset_api_key: "true", reset_api_keys: "true", password: PasswordHelpers::SECURE_TEST_PASSWORD }
        }

        assert_redirected_to sign_in_path
        assert_equal "Please double check the URL or try submitting a new password reset.", flash[:alert]

        @user.reload

        assert_equal @user.api_key, @api_key
        assert_equal @user.encrypted_password, @old_encrypted_password
        refute_signed_in
      end
    end

    context "when verification has expired" do
      should "redirect to the sign in page" do
        get edit_password_path, params: { token: @user.confirmation_token }
        travel 16.minutes do
          put password_path, params: {
            password_reset: { password: PasswordHelpers::SECURE_TEST_PASSWORD }
          }
        end

        assert_redirected_to sign_in_path
        assert_equal I18n.t("verification_expired"), flash[:alert]

        @user.reload

        assert_equal @user.api_key, @api_key
        assert_equal @user.encrypted_password, @old_encrypted_password
        refute_signed_in
      end
    end

    context "with invalid password" do
      should "redisplay edit form and not change password" do
        get edit_password_path, params: { token: @user.confirmation_token }
        put password_path, params: {
          password_reset: { reset_api_key: "true", password: "pass" }
        }

        assert_response :unprocessable_entity
        assert_select "#flash_alert", "Your password could not be changed. Please try again."
        assert_select "h1", "Reset password"
        assert_select "#errorExplanation", /Password is too short \(minimum is 10 characters\)/
        assert_select "form[action=?]", password_path do
          assert_select "input[type=password][autocomplete=new-password]"
        end

        @user.reload

        assert_equal @user.api_key, @api_key
        assert_equal @user.encrypted_password, @old_encrypted_password
      end
    end

    context "with valid password without reset_api_key" do
      should "change password but not change api_key" do
        get edit_password_path, params: { token: @user.confirmation_token }
        put password_path, params: {
          password_reset: { password: PasswordHelpers::SECURE_TEST_PASSWORD }
        }

        assert_redirected_to sign_in_path
        assert_equal "Your password has been changed.", flash[:notice]

        @user.reload

        assert_equal @user.api_key, @api_key
        refute_equal @user.encrypted_password, @old_encrypted_password
      end
    end

    context "with valid password with reset_api_key false" do
      should "change password but not change api_key" do
        get edit_password_path, params: { token: @user.confirmation_token }
        put password_path, params: {
          password_reset: { reset_api_key: "false", password: PasswordHelpers::SECURE_TEST_PASSWORD }
        }

        assert_redirected_to sign_in_path
        # assert_equal "Your password has been changed.", flash[:notice]

        @user.reload

        assert_equal @user.api_key, @api_key
        refute_equal @user.encrypted_password, @old_encrypted_password
      end
    end

    context "with valid password with reset_api_key" do
      should "change password and reset api_key" do
        get edit_password_path, params: { token: @user.confirmation_token }
        put password_path, params: {
          password_reset: { reset_api_key: "true", password: PasswordHelpers::SECURE_TEST_PASSWORD }
        }

        assert_redirected_to sign_in_path
        assert_equal "Your password has been changed.", flash[:notice]

        @user.reload

        refute_equal @user.api_key, @api_key
        refute_equal @user.encrypted_password, @old_encrypted_password

        refute_predicate @new_api_key.reload, :destroyed?
        refute_empty @user.api_keys
      end
    end

    context "with valid password with reset_api_key and reset_api_keys" do
      should "change password, reset legacy api_key, and expire all api_keys" do
        get edit_password_path, params: { token: @user.confirmation_token }
        put password_path, params: {
          password_reset: { reset_api_key: "true", reset_api_keys: "true", password: PasswordHelpers::SECURE_TEST_PASSWORD }
        }

        assert_redirected_to sign_in_path
        # assert_equal "Your password has been changed.", flash[:notice]

        @user.reload

        refute_equal @user.api_key, @api_key
        refute_equal @user.encrypted_password, @old_encrypted_password
        assert_empty @user.api_keys.unexpired
        refute_empty @user.api_keys.expired
      end
    end
  end

  private

  def webauthn_result(challenge = nil)
    challenge ||= session["webauthn_authentication"]["challenge"]
    WebauthnHelpers.create_credential(webauthn_credential: @webauthn_credential, client: @client)
    WebauthnHelpers.get_result(client: @client, challenge:)
  end

  def assert_otp_form
    assert_select "h1", "Multi-factor authentication"
    assert_select "form[action=?]", otp_edit_password_url(token: @user.confirmation_token) do
      assert_select "input[type=text][autocomplete=one-time-code]"
      assert_select "input[type=submit][value=?]", I18n.t("authenticate")
    end
  end

  def assert_webauthn_form
    assert_select "h1", "Multi-factor authentication"
    assert_select "p", "Authenticate with a security device such as Touch ID, YubiKey, etc."
    assert_select "form.js-webauthn-session--form[action=?]", webauthn_edit_password_url(token: @user.confirmation_token) do
      assert_select "input[type=submit][value=?]", I18n.t("multifactor_auths.prompt.sign_in_with_webauthn_credential")
    end
  end

  def assert_new_password_form
    assert_select "h1", I18n.t("passwords.edit.title")
    assert_select "form[action=?]", password_path do
      assert_select "input[type=password][autocomplete=new-password][name=?]", "password_reset[password]"
      assert_select "input[type=checkbox][name=?]", "password_reset[reset_api_key]"
      assert_select "input[type=checkbox][name=?]", "password_reset[reset_api_keys]"
      assert_select "input[type=submit][value=?]", I18n.t("passwords.edit.submit")
    end
  end
end
