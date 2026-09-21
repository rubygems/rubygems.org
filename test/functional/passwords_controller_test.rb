# frozen_string_literal: true

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
      should "enqueue the mail without putting the raw token in job arguments" do
        @user = create(:user)

        assert_enqueued_email_with PasswordMailer, :change_password, args: [@user] do
          post password_path, params: { password: { email: @user.email } }
        end
      end

      should "invalidate an existing reset token before the mail job runs" do
        @user = create(:user)
        token = @user.issue_password_reset!

        post password_path, params: { password: { email: @user.email } }

        refute @user.reload.valid_password_reset_token?(token)
        assert_nil @user.password_reset_token_digest
        assert_nil @user.password_reset_token_expires_at
      end

      should "store only a digest of the password reset token" do
        @user = create(:user)

        assert_nil @user.confirmation_token

        perform_enqueued_jobs do
          post password_path, params: { password: { email: @user.email } }
        end

        assert_select "p", "You will receive an email within the next few minutes. It contains instructions for changing your password."
        refute_nil @user.reload.password_reset_token_digest
        assert_nil @user.confirmation_token
        assert_in_delta 3.hours.from_now, @user.password_reset_token_expires_at, 2.seconds
      end
    end
  end

  context "on GET to edit" do
    setup do
      @user = create(:user)
      @token = @user.issue_password_reset!
    end

    context "with incorrect token" do
      should "redirect to the sign in page" do
        get edit_password_path, params: { token: "invalidtoken" }

        assert_redirected_to sign_in_path
        assert_equal "Please double check the URL or try submitting a new password reset.", flash[:alert]
        refute_signed_in
      end
    end

    context "with a valid password reset token" do
      context "when not signed in" do
        should "present the password edit form directly without relying on JavaScript" do
          get edit_password_path, params: { token: @token }

          assert_response :success
          assert_new_password_form
          assert_password_reset_response_headers
        end

        should "presents the password edit form" do
          begin_password_reset

          assert_response :success
          assert_new_password_form

          assert @user.reload.valid_password_reset_token?(@token)
          refute_signed_in
          assert_equal edit_password_path, request.path
        end
      end

      context "when signed in as the user" do
        should "presents the password edit form" do
          begin_password_reset(as: @user)

          assert_response :success
          assert_new_password_form

          assert @user.reload.valid_password_reset_token?(@token)
        end
      end

      context "when signed in as another user" do
        should "presents the password edit form for the token identified user, signing the other user out" do
          @other_user = create(:user, api_key: "otheruserkey")

          begin_password_reset(as: @other_user)

          assert_response :success
          assert_new_password_form

          refute_signed_in
          assert @user.reload.valid_password_reset_token?(@token)
        end
      end
    end

    context "with a signed compromised reason" do
      should "show compromised warning banner" do
        @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
        begin_password_reset(reason: @user.compromised_password_reset_reason_for(@token))

        assert_response :success
        assert_new_password_form
        assert page.has_content?(I18n.t("passwords.edit.compromised_heading"))
      end
    end

    context "with an unsigned compromised reason" do
      should "not treat the reset as compromised" do
        begin_password_reset(reason: "compromised")

        assert_response :success
        refute page.has_content?(I18n.t("passwords.edit.compromised_heading"))
      end

      should "not bypass enabled MFA" do
        @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
        begin_password_reset(reason: "compromised")

        assert_response :success
        assert_otp_form
      end
    end

    context "without reason param" do
      should "not show compromised warning banner" do
        begin_password_reset

        assert_response :success
        refute page.has_content?(I18n.t("passwords.edit.compromised_heading"))
      end
    end

    context "with an expired password reset token" do
      should "redirect to the sign in page" do
        @user.update_attribute(:password_reset_token_expires_at, 1.minute.ago)
        get edit_password_path, params: { token: @token }

        assert_redirected_to sign_in_path
        assert_equal I18n.t("passwords.edit.token_failure"), flash[:alert]
        refute_signed_in
      end
    end

    context "with totp enabled" do
      should "display otp form" do
        @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
        begin_password_reset

        assert_response :success
        assert_otp_form
        refute_signed_in
      end
    end

    context "when user has webauthn credentials but no recovery codes" do
      should "display webauthn prompt only" do
        create(:webauthn_credential, user: @user)
        @user.update!(new_mfa_recovery_codes: nil, mfa_hashed_recovery_codes: [])

        begin_password_reset

        assert_response :success
        assert_webauthn_form
        refute page.has_content?("Recovery code"), "Recovery code form should not be displayed"
        refute_signed_in
      end
    end

    context "when user has webauthn credentials and recovery codes" do
      should "display webauthn prompt and recovery code prompt" do
        create(:webauthn_credential, user: @user)
        begin_password_reset

        assert_response :success
        assert_webauthn_form
        assert_select "form[action=?]", otp_edit_password_url do
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

        begin_password_reset

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
      @token = @user.issue_password_reset!
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
          begin_password_reset
          post otp_edit_password_path, params: { otp: ROTP::TOTP.new(@user.totp_seed).now }
          follow_redirect!

          assert_response :success
          assert_new_password_form

          refute_signed_in
          assert @user.reload.valid_password_reset_token?(@token)
          assert_nil session[:mfa_expires_at]
        end
      end

      context "when OTP is incorrect" do
        should "display error message and prompt for MFA again" do
          begin_password_reset
          post otp_edit_password_path, params: { otp: "wrong" }

          assert_response :unauthorized
          assert page.has_content?("Your OTP code is incorrect.")
          assert_otp_form

          refute_signed_in
        end
      end

      context "when the OTP session is expired" do
        should "redirect to the sign in page" do
          begin_password_reset
          travel 16.minutes do
            post otp_edit_password_path, params: { otp: ROTP::TOTP.new(@user.totp_seed).now }
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
      @token = @user.issue_password_reset!
      @webauthn_credential = create(:webauthn_credential, user: @user)

      @origin = WebAuthn.configuration.allowed_origins.first
      @rp_id = URI.parse(@origin).host
      @client = WebAuthn::FakeClient.new(@origin, encoding: false)
    end

    context "with correct webauthn" do
      should "display edit form" do
        begin_password_reset
        post webauthn_edit_password_path, params: {
          credentials: webauthn_result
        }
        follow_redirect!

        assert_response :success
        assert_new_password_form

        refute_signed_in
        assert @user.reload.valid_password_reset_token?(@token)
        assert_nil session[:mfa_expires_at]
      end
    end

    context "when the password reset token has been invalidated" do
      should "redirect to the sign in page" do
        begin_password_reset
        credentials = webauthn_result
        @user.invalidate_password_reset!
        post webauthn_edit_password_path, params: { credentials: }

        assert_redirected_to sign_in_path
        assert_equal "Please double check the URL or try submitting a new password reset.", flash[:alert]

        assert_nil session[:mfa_expires_at]
        refute_signed_in
      end
    end

    context "when not providing credentials" do
      should "display error message and prompt for MFA again" do
        begin_password_reset
        post webauthn_edit_password_path

        assert_response :unauthorized
        assert page.has_content?("Credentials required")
        assert_webauthn_form

        refute_signed_in
      end
    end

    context "when providing wrong credential" do
      should "display error message and prompt for MFA again" do
        begin_password_reset
        wrong_challenge = SecureRandom.hex
        post webauthn_edit_password_path, params: {
          credentials: webauthn_result(wrong_challenge)
        }

        assert_response :unauthorized
        assert page.has_content?("WebAuthn::ChallengeVerificationError")
        assert_webauthn_form

        refute_signed_in
      end
    end

    context "when webauthn session is expired" do
      should "redirect to the sign in page" do
        begin_password_reset
        travel 16.minutes do
          post webauthn_edit_password_path, params: {
            credentials: webauthn_result
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
      @token = @user.issue_password_reset!
      @api_key = @user.api_key
      @new_api_key = create(:api_key, owner: @user)
      @old_encrypted_password = @user.encrypted_password
    end

    context "when not verified for password reset" do
      should "redirect to the sign in page" do
        put password_path, params: {
          password_reset: { reset_api_key: "true", reset_api_keys: "true",
                            password: PasswordHelpers::SECURE_TEST_PASSWORD }
        }

        assert_redirected_to sign_in_path
        assert_equal "Please double check the URL or try submitting a new password reset.", flash[:alert]

        @user.reload

        assert_equal @user.api_key, @api_key
        assert_equal @user.encrypted_password, @old_encrypted_password
        refute_signed_in
      end
    end

    context "with an invalid authenticity token" do
      should "reject the update with password reset security headers" do
        original_allow_forgery_protection = ActionController::Base.allow_forgery_protection
        begin_password_reset
        ActionController::Base.allow_forgery_protection = true

        put password_path, params: {
          password_reset: { password: PasswordHelpers::SECURE_TEST_PASSWORD }
        }

        assert_response :forbidden
        assert_password_reset_response_headers
        assert_equal @old_encrypted_password, @user.reload.encrypted_password
      ensure
        ActionController::Base.allow_forgery_protection = original_allow_forgery_protection
      end
    end

    context "when verification has expired" do
      should "redirect to the sign in page" do
        begin_password_reset
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

    context "when the reset token expires after opening the form" do
      should "reject the password update" do
        @user.update!(password_reset_token_expires_at: 1.minute.from_now)
        begin_password_reset

        travel 2.minutes do
          put password_path, params: {
            password_reset: { password: PasswordHelpers::SECURE_TEST_PASSWORD }
          }
        end

        assert_redirected_to sign_in_path
        assert_equal I18n.t("passwords.edit.token_failure"), flash[:alert]
        assert_equal @old_encrypted_password, @user.reload.encrypted_password
      end
    end

    context "with invalid password" do
      should "redisplay edit form and not change password" do
        begin_password_reset
        put password_path, params: {
          password_reset: { reset_api_key: "true", password: "pass" }
        }

        assert_response :unprocessable_content
        assert page.has_content?("Your password could not be changed. Please try again.")
        assert_select "h1", "Reset password"
        assert page.has_content?("Password is too short (minimum is 10 characters)")
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
        begin_password_reset
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
        begin_password_reset
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
        begin_password_reset
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
        begin_password_reset
        put password_path, params: {
          password_reset: { reset_api_key: "true", reset_api_keys: "true",
                            password: PasswordHelpers::SECURE_TEST_PASSWORD }
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

  def begin_password_reset(as: nil, reason: nil)
    path = as ? edit_password_path(as:) : edit_password_path
    reset_params = { token: @token }
    reset_params[:reason] = reason if reason

    get path, params: reset_params

    assert_response :success
    assert_password_reset_response_headers
  end

  def assert_password_reset_response_headers
    assert_equal "private, no-store", response.headers["Cache-Control"]
    assert_includes %w[no-store max-age=0], response.headers["Surrogate-Control"]
    assert_equal "no-referrer", response.headers["Referrer-Policy"]
  end

  def webauthn_result(challenge = nil)
    challenge ||= session["webauthn_authentication"]["challenge"]
    WebauthnHelpers.create_credential(webauthn_credential: @webauthn_credential, client: @client)
    WebauthnHelpers.get_result(client: @client, challenge:)
  end

  def assert_otp_form
    assert_select "h2", I18n.t("multifactor_auths.prompt.otp_code")
    assert_select "form[action=?]", otp_edit_password_url do
      assert_select "input[type=text][autocomplete=one-time-code]"
      assert_select "input[type=submit][value=?]", I18n.t("authenticate")
    end
  end

  def assert_webauthn_form
    assert_select "h2", I18n.t("multifactor_auths.prompt.security_device")
    assert_select "p", I18n.t("multifactor_auths.prompt.webauthn_credential_note")
    assert_select "form.js-webauthn-session--form[action=?]", webauthn_edit_password_url do
      assert_select "input[type=submit][value=?]", I18n.t("multifactor_auths.prompt.sign_in_with_webauthn_credential")
    end
  end

  def assert_new_password_form
    assert_select "h1", I18n.t("passwords.edit.title")
    assert_select "form[action=?]", password_path do
      assert_select "input[type=password][autocomplete=new-password][name=?]", "password_reset[password]"
      assert_select "input[type=checkbox][name=?]", "password_reset[reset_api_key]"
      assert_select "input[type=checkbox][name=?]", "password_reset[reset_api_keys]"
      assert_select "button[type=submit]", text: I18n.t("passwords.edit.submit")
    end
  end
end
