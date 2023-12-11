require "test_helper"

class MultifactorAuthsControllerTest < ActionController::TestCase
  include ActionMailer::TestHelper

  context "when logged in" do
    setup do
      @user = create(:user)
      sign_in_as(@user)
      @request.cookies[:mfa_feature] = "true"
    end

    context "when totp is enabled" do
      setup do
        @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
      end

      context "on GET to new totp" do
        setup do
          get :new
        end

        should respond_with :redirect
        should redirect_to("the settings page") { edit_settings_path }

        should "say TOTP is already enabled" do
          assert_equal "Your OTP based multi-factor authentication has already been enabled. " \
                       "To reconfigure your OTP based authentication, you'll have to remove it first.", flash[:error]
        end
      end

      context "on POST to create mfa" do
        setup do
          @seed = ROTP::Base32.random_base32
          @controller.session[:totp_seed] = @seed
          @controller.session[:totp_seed_expire] = Gemcutter::MFA_KEY_EXPIRY.from_now.utc.to_i
          post :create, params: { otp: ROTP::TOTP.new(@user.totp_seed).now }
        end

        should respond_with :redirect
        should redirect_to("the settings page") { edit_settings_path }

        should "keep mfa enabled" do
          assert_predicate @user.reload, :mfa_enabled?
          assert_emails 0
        end

        should "say TOTP is already enabled" do
          assert_equal "Your OTP based multi-factor authentication has already been enabled. " \
                       "To reconfigure your OTP based authentication, you'll have to remove it first.", flash[:error]
        end
      end

      context "on PUT to update mfa level" do
        setup do
          freeze_time
          put :update, params: { level: "ui_and_api" }
        end

        should "render totp prompt" do
          assert page.has_content?("OTP code")
          refute page.has_content?("Security Device")
        end

        should "not update mfa level" do
          assert_predicate @user.reload, :mfa_ui_only?
        end

        should "set mfa level in session" do
          assert_equal "ui_and_api", @controller.session[:level]
        end

        should "set expiry in session" do
          assert_equal 15.minutes.from_now.to_s, session[:mfa_expires_at]
        end

        teardown do
          travel_back
        end
      end

      context "on POST to otp_update" do
        context "when updating to ui_and_api" do
          context "when redirect url is not set" do
            setup do
              put :update, params: { level: "ui_and_api" }
              post :otp_update, params: { otp: ROTP::TOTP.new(@user.totp_seed).now }
            end

            should redirect_to("the settings page") { edit_settings_path }

            should "update mfa level" do
              assert_predicate @user.reload, :mfa_ui_and_api?
            end

            should "clear session variables" do
              assert_nil @controller.session[:mfa_expires_at]
              assert_nil @controller.session[:level]
            end
          end

          context "when redirect url is set" do
            setup do
              @controller.session["mfa_redirect_uri"] = profile_api_keys_path
              put :update, params: { level: "ui_and_api" }
              post :otp_update, params: { otp: ROTP::TOTP.new(@user.totp_seed).now }
            end

            should redirect_to("the api keys index") { profile_api_keys_path }
          end
        end

        context "when updating to ui_and_gem_signin" do
          context "when redirect url is not set" do
            setup do
              put :update, params: { level: "ui_and_gem_signin" }
              post :otp_update, params: { otp: ROTP::TOTP.new(@user.totp_seed).now }
            end

            should redirect_to("the settings page") { edit_settings_path }

            should "update mfa level" do
              assert_predicate @user.reload, :mfa_ui_and_gem_signin?
            end

            should "clear session variables" do
              assert_nil @controller.session[:mfa_expires_at]
              assert_nil @controller.session[:level]
            end
          end

          context "when redirect url is set" do
            setup do
              @controller.session["mfa_redirect_uri"] = profile_api_keys_path
              put :update, params: { level: "ui_and_api" }
              post :otp_update, params: { otp: ROTP::TOTP.new(@user.totp_seed).now }
            end

            should redirect_to("the api keys index") { profile_api_keys_path }
          end
        end

        context "when otp is incorrect" do
          setup do
            put :update, params: { level: "ui_and_api" }
            post :otp_update, params: { otp: "123456" }
          end

          should redirect_to("the settings page") { edit_settings_path }

          should "not update mfa level" do
            assert_predicate @user.reload, :mfa_ui_only?
          end

          should "set flash error" do
            assert_equal "Your OTP code is incorrect.", flash[:error]
          end

          should "clear session variables" do
            assert_nil @controller.session[:mfa_expires_at]
            assert_nil @controller.session[:level]
            assert_nil @controller.session[:mfa_redirect_uri]
          end
        end

        context "when mfa level is invalid" do
          setup do
            put :update, params: { level: "disabled" }
            post :otp_update, params: { otp: ROTP::TOTP.new(@user.totp_seed).now }
          end

          should "set flash error" do
            assert_equal "Invalid MFA level.", flash[:error]
          end

          should redirect_to("the settings page") { edit_settings_path }
        end

        context "when session is expired" do
          setup do
            get :update, params: { level: "ui_and_api" }

            travel 16.minutes do
              post :otp_update, params: { otp: ROTP::TOTP.new(@user.totp_seed).now }
            end
          end

          should redirect_to("the settings page") { edit_settings_path }

          should "not update mfa level" do
            assert_predicate @user.reload, :mfa_ui_only?
          end

          should "set flash error" do
            assert_equal "Your login page session has expired.", flash[:error]
          end

          should "clear session variables" do
            assert_nil @controller.session[:mfa_expires_at]
            assert_nil @controller.session[:level]
            assert_nil @controller.session[:mfa_redirect_uri]
          end
        end
      end

      context "on POST to webauthn_update" do
        setup do
          put :update, params: { level: "ui_and_api" }
          post :webauthn_update
        end

        should redirect_to("the settings page") { edit_settings_path }

        should "set flash error" do
          assert_equal "You don't have any security devices enabled. " \
                       "You have to associate a device to your account first.", flash[:error]
        end

        should "not update mfa level" do
          assert_predicate @user.reload, :mfa_ui_only?
        end

        should "clear session variables" do
          assert_nil @controller.session[:mfa_expires_at]
          assert_nil @controller.session[:level]
          assert_nil @controller.session[:mfa_redirect_uri]
        end
      end

      context "on DELETE to destroy" do
        context "with correct OTP" do
          setup do
            @controller.session["mfa_redirect_uri"] = edit_settings_path

            perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
              delete :destroy, params: { otp: ROTP::TOTP.new(@user.totp_seed).now }
            end
          end

          should respond_with :redirect
          should redirect_to("the settings page") { edit_settings_path }

          should "disable mfa and clear recovery codes" do
            assert_predicate @user.reload, :totp_disabled?
            assert_predicate @user.reload, :mfa_disabled?
            assert_empty @user.mfa_hashed_recovery_codes
          end

          should "send mfa disabled email" do
            assert_emails 1

            assert_equal "Authentication app disabled on RubyGems.org",
                         last_email.subject
            assert_equal [@user.email], last_email.to
          end

          should "flash success" do
            assert_equal "You have successfully disabled OTP based multi-factor authentication.", flash[:success]
          end

          should "delete mfa_redirect_uri from session" do
            assert_nil session[:mfa_redirect_uri]
          end
        end

        context "with incorrect OTP" do
          setup do
            @controller.session["mfa_redirect_uri"] = edit_settings_path

            perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
              delete :destroy, params: { otp: "123456" }
            end
          end

          should respond_with :redirect
          should redirect_to("the settings page") { edit_settings_path }

          should "keep mfa and recovery codes enabled" do
            assert_predicate @user.reload, :totp_enabled?
            assert_not_empty @user.mfa_hashed_recovery_codes
          end

          should "flash error" do
            assert_equal "Your OTP code is incorrect.", flash[:error]
          end

          should "not send mfa disabled email" do
            assert_emails 0
          end

          should "not clear mfa_redirect_uri from session" do
            assert_not_nil session[:mfa_redirect_uri]
          end
        end
      end
    end

    context "when a webauthn device is enabled" do
      setup do
        @webauthn_credential = create(:webauthn_credential, user: @user)
        @user.update!(mfa_level: :ui_only)
      end

      context "on POST to create totp mfa" do
        setup do
          @seed = ROTP::Base32.random_base32
          @controller.session[:totp_seed] = @seed
          @controller.session[:totp_seed_expire] = Gemcutter::MFA_KEY_EXPIRY.from_now.utc.to_i
          perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
            post :create, params: { otp: ROTP::TOTP.new(@seed).now }
          end
        end

        should redirect_to("the edit settings page") { edit_settings_path }

        should "send totp enabled email" do
          assert_emails 1
          assert_equal "Authentication app enabled on RubyGems.org",
                       last_email.subject
          assert_equal [@user.email], last_email.to
        end
      end

      context "on PUT to update mfa level" do
        setup do
          freeze_time
        end

        context "when user has recovery codes" do
          setup do
            put :update, params: { level: "ui_and_api" }
          end

          should "render webauthn prompt" do
            refute page.has_content?("OTP code")
            assert page.has_content?("Security Device")
          end

          should "render recovery code prompt" do
            assert page.has_content?("Recovery code")
          end

          should "not update mfa level" do
            assert_predicate @user.reload, :mfa_ui_only?
          end

          should "set mfa level in session" do
            assert_equal "ui_and_api", @controller.session[:level]
          end

          should "set expiry in session" do
            assert_equal 15.minutes.from_now.to_s, session[:mfa_expires_at]
          end
        end

        context "when user does not have recovery codes" do
          setup do
            @user.update!(mfa_hashed_recovery_codes: [])
            @user.new_mfa_recovery_codes = nil
            put :update, params: { level: "ui_and_api" }
          end

          should "not render recovery code prompt" do
            refute page.has_content?("Recovery code")
          end
        end

        teardown do
          travel_back
        end
      end

      context "on POST to otp_update with correct recovery codes" do
        setup do
          put :update, params: { level: "ui_and_api" }
          post :otp_update, params: { otp: @user.new_mfa_recovery_codes.first }
        end

        should redirect_to("the settings page") { edit_settings_path }

        should "update mfa level" do
          assert_predicate @user.reload, :mfa_ui_and_api?
        end

        should "clear session variables" do
          assert_nil @controller.session[:mfa_expires_at]
          assert_nil @controller.session[:level]
          assert_nil @controller.session[:webauthn_authentication]
        end
      end

      context "on POST to otp_update with incorrect recovery codes" do
        setup do
          put :update, params: { level: "ui_and_api" }
          post :otp_update, params: { otp: "blah" }
        end

        should redirect_to("the settings page") { edit_settings_path }

        should "not update mfa level" do
          assert_predicate @user.reload, :mfa_ui_only?
        end

        should "set flash error" do
          assert_equal "Your OTP code is incorrect.", flash[:error]
        end
      end

      context "on POST to webauthn_update" do
        setup do
          @origin = WebAuthn.configuration.origin
          @rp_id = URI.parse(@origin).host
          @client = WebAuthn::FakeClient.new(@origin, encoding: false)
          WebauthnHelpers.create_credential(
            webauthn_credential: @webauthn_credential,
            client: @client
          )
        end

        context "when updating to ui and api" do
          setup do
            put :update, params: { level: "ui_and_api" }
            @challenge = session[:webauthn_authentication]["challenge"]
          end

          context "redirect url is not set" do
            setup do
              post(
                :webauthn_update,
                params: {
                  credentials:
                    WebauthnHelpers.get_result(
                      client: @client,
                      challenge: @challenge
                    )
                }
              )
            end

            should redirect_to("the settings page") { edit_settings_path }

            should "update mfa level" do
              assert_predicate @user.reload, :mfa_ui_and_api?
            end

            should "clear session variables" do
              assert_nil @controller.session[:mfa_expires_at]
              assert_nil @controller.session[:level]
              assert_nil @controller.session[:webauthn_authentication]
            end
          end

          context "when redirect url is set" do
            setup do
              @controller.session["mfa_redirect_uri"] = profile_api_keys_path
              post(
                :webauthn_update,
                params: {
                  credentials:
                    WebauthnHelpers.get_result(
                      client: @client,
                      challenge: @challenge
                    )
                }
              )
            end

            should redirect_to("the api keys index") { profile_api_keys_path }
          end
        end

        context "when updating to ui and gem signin" do
          setup do
            put :update, params: { level: "ui_and_gem_signin" }
            @challenge = session[:webauthn_authentication]["challenge"]
          end

          context "redirect url is not set" do
            setup do
              post(
                :webauthn_update,
                params: {
                  credentials:
                    WebauthnHelpers.get_result(
                      client: @client,
                      challenge: @challenge
                    )
                }
              )
            end

            should redirect_to("the settings page") { edit_settings_path }

            should "update mfa level" do
              assert_predicate @user.reload, :mfa_ui_and_gem_signin?
            end

            should "clear session variables" do
              assert_nil @controller.session[:mfa_expires_at]
              assert_nil @controller.session[:level]
              assert_nil @controller.session[:webauthn_authentication]
            end
          end

          context "when redirect url is set" do
            setup do
              @controller.session["mfa_redirect_uri"] = profile_api_keys_path
              post(
                :webauthn_update,
                params: {
                  credentials:
                    WebauthnHelpers.get_result(
                      client: @client,
                      challenge: @challenge
                    )
                }
              )
            end

            should redirect_to("the api keys index") { profile_api_keys_path }
          end
        end

        context "when not providing credentials" do
          setup do
            put :update, params: { level: "ui_and_api" }
            post :webauthn_update
          end

          should redirect_to("the settings page") { edit_settings_path }

          should "set flash error" do
            assert_equal "Credentials required", flash[:error]
          end
        end

        context "when providing wrong credential" do
          setup do
            put :update, params: { level: "ui_and_api" }
            @wrong_challenge = SecureRandom.hex
            post(
              :webauthn_update,
              params: {
                credentials:
                WebauthnHelpers.get_result(
                  client: @client,
                  challenge: @wrong_challenge
                )
              }
            )
          end

          should redirect_to("the settings page") { edit_settings_path }

          should "set flash notice" do
            assert_equal "WebAuthn::ChallengeVerificationError", flash[:error]
          end

          should "clear session variables" do
            assert_nil @controller.session[:mfa_expires_at]
            assert_nil @controller.session[:level]
            assert_nil @controller.session[:webauthn_authentication]
          end
        end

        context "when webauthn session is expired" do
          setup do
            put :update, params: { level: "ui_and_api" }
            @challenge = session[:webauthn_authentication]["challenge"]
            travel 16.minutes do
              post(
                :webauthn_update,
                params: {
                  credentials:
                  WebauthnHelpers.get_result(
                    client: @client,
                    challenge: @challenge
                  )
                }
              )
            end
          end

          should redirect_to("the settings page") { edit_settings_path }

          should "set flash error" do
            assert_equal "Your login page session has expired.", flash[:error]
          end

          should "clear session variables" do
            assert_nil @controller.session[:mfa_expires_at]
            assert_nil @controller.session[:level]
            assert_nil @controller.session[:webauthn_authentication]
          end
        end

        context "to update to invalid level" do
          setup do
            put :update, params: { level: "disabled" }
            @challenge = session[:webauthn_authentication]["challenge"]
          end

          should "not update level" do
            assert_no_changes -> { @user.reload.mfa_level } do
              post(
                :webauthn_update,
                params: {
                  credentials:
                    WebauthnHelpers.get_result(
                      client: @client,
                      challenge: @challenge
                    )
                }
              )
            end
          end

          should "display flash error" do
            post(
              :webauthn_update,
              params: {
                credentials:
                  WebauthnHelpers.get_result(
                    client: @client,
                    challenge: @challenge
                  )
              }
            )

            assert_equal "Invalid MFA level.", flash[:error]
          end
        end
      end

      context "on DELETE to destroy" do
        should "redirect to settings page" do
          delete :destroy

          assert_redirected_to edit_settings_path
        end

        should "not change mfa level and recovery codes" do
          assert_no_changes -> { [@user.reload.mfa_level, @user.reload.mfa_hashed_recovery_codes] } do
            delete :destroy
          end
        end

        should "display flash error" do
          delete :destroy

          assert_equal "You don't have an authenticator app enabled. You have to enable it first.", flash[:error]
        end
      end
    end

    context "when there are no mfa devices" do
      context "on POST to create totp mfa" do
        setup do
          @seed = ROTP::Base32.random_base32
          @controller.session[:totp_seed] = @seed
        end

        context "when qr-code is not expired" do
          setup do
            perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
              @controller.session[:totp_seed_expire] = Gemcutter::MFA_KEY_EXPIRY.from_now.utc.to_i
              post :create, params: { otp: ROTP::TOTP.new(@seed).now }
            end
          end

          should redirect_to("the recovery page") { recovery_multifactor_auth_path }

          should "enable mfa" do
            assert_predicate @user.reload, :mfa_enabled?
          end

          should "send totp enabled email" do
            assert_emails 1
            assert_equal "Authentication app enabled on RubyGems.org",
                         last_email.subject
            assert_equal [@user.email], last_email.to
          end

          should "flash success" do
            assert_equal "You have successfully enabled OTP based multi-factor authentication.", flash[:success]
          end
        end

        context "when qr-code is expired" do
          setup do
            @controller.session[:totp_seed_expire] = 1.minute.ago
            post :create, params: { otp: ROTP::TOTP.new(@seed).now }
          end

          should respond_with :redirect
          should redirect_to("the settings page") { edit_settings_path }

          should "set error flash message" do
            refute_empty flash[:error]
          end
          should "keep mfa disabled" do
            refute_predicate @user.reload, :mfa_enabled?
          end
          should "not send mfa enabled email" do
            assert_emails 0
          end
        end
      end

      context "on PUT to update mfa level" do
        setup do
          put :update
        end

        should respond_with :redirect
        should redirect_to("the settings page") { edit_settings_path }

        should "keep mfa disabled" do
          refute_predicate @user.reload, :mfa_enabled?
        end

        should "say MFA is not enabled" do
          assert_equal "Your multi-factor authentication has not been enabled. " \
                       "You have to enable it first.", flash[:error]
        end
      end

      context "on POST to otp_update" do
        setup do
          post :otp_update
        end

        should respond_with :redirect
        should redirect_to("the settings page") { edit_settings_path }

        should "keep mfa disabled" do
          refute_predicate @user.reload, :mfa_enabled?
        end

        should "say MFA is not enabled" do
          assert_equal "Your multi-factor authentication has not been enabled. You have to enable it first.", flash[:error]
        end
      end

      context "on POST to webauthn_update" do
        setup do
          @controller.create_new_mfa_expiry
          post :webauthn_update
        end

        should redirect_to("the settings page") { edit_settings_path }

        should "set flash error" do
          assert_equal "You don't have any security devices enabled. " \
                       "You have to associate a device to your account first.", flash[:error]
        end
      end

      context "on DELETE to destroy" do
        should "redirect to settings page" do
          delete :destroy

          assert_redirected_to edit_settings_path
        end

        should "not change mfa level and recovery codes" do
          assert_no_changes -> { [@user.reload.mfa_level, @user.reload.mfa_hashed_recovery_codes] } do
            delete :destroy
          end
        end

        should "display flash error" do
          delete :destroy

          assert_equal "You don't have an authenticator app enabled. You have to enable it first.", flash[:error]
        end
      end
    end

    context "when totp and webauthn are enabled" do
      setup do
        @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
        @webauthn_credential = create(:webauthn_credential, user: @user)
      end

      context "on PUT to update mfa level" do
        setup do
          put :update, params: { level: "ui_and_api" }
        end

        should "render totp prompt" do
          assert page.has_content?("OTP code")
        end

        should "render webauthn prompt" do
          assert page.has_content?("Security Device")
        end
      end

      context "on POST to otp_update" do
        setup do
          @controller.session["mfa_redirect_uri"] = profile_api_keys_path
          put :update, params: { level: "ui_and_api" }
          post :otp_update, params: { otp: ROTP::TOTP.new(@user.totp_seed).now }
        end

        should redirect_to("the api keys index") { profile_api_keys_path }

        should "update mfa level" do
          assert_predicate @user.reload, :mfa_ui_and_api?
        end

        should "clear session variables" do
          assert_nil @controller.session[:mfa_expires_at]
          assert_nil @controller.session[:level]
        end
      end

      context "on POST to webauthn_update" do
        setup do
          origin = WebAuthn.configuration.origin
          @rp_id = URI.parse(origin).host
          @client = WebAuthn::FakeClient.new(origin, encoding: false)
          WebauthnHelpers.create_credential(
            webauthn_credential: @webauthn_credential,
            client: @client
          )
          @controller.session["mfa_redirect_uri"] = profile_api_keys_path
          put :update, params: { level: "ui_and_api" }
          post(
            :webauthn_update,
            params: {
              credentials:
                WebauthnHelpers.get_result(
                  client: @client,
                  challenge: session[:webauthn_authentication]["challenge"]
                )
            }
          )
        end

        should redirect_to("the api keys index") { profile_api_keys_path }

        should "update mfa level" do
          assert_predicate @user.reload, :mfa_ui_and_api?
        end

        should "clear session variables" do
          assert_nil @controller.session[:mfa_expires_at]
          assert_nil @controller.session[:level]
        end
      end
    end

    context "on GET to recovery" do
      context "when show_recovery_codes is array" do
        setup do
          @controller.session[:show_recovery_codes] = %w[aaa bbb]
          get :recovery
        end

        should respond_with :success

        should "clear show_recovery_codes" do
          assert_nil @controller.session[:show_recovery_codes]
        end
      end

      context "when show_recovery_codes is not set" do
        setup do
          get :recovery
        end

        should respond_with :redirect
        should redirect_to("the settings page") { edit_settings_path }

        should "set error flash message" do
          assert_equal "You should have already saved your recovery codes.", flash[:error]
        end
      end
    end

    context "when user owns a gem with more than MFA_REQUIRED_THRESHOLD downloads" do
      setup do
        @rubygem = create(:rubygem)
        create(:ownership, rubygem: @rubygem, user: @user)
        GemDownload.increment(
          Rubygem::MFA_REQUIRED_THRESHOLD + 1,
          rubygem_id: @rubygem.id
        )
        @redirect_paths = [adoptions_profile_path,
                           dashboard_path,
                           delete_profile_path,
                           edit_profile_path,
                           new_profile_api_key_path,
                           notifier_path,
                           profile_api_keys_path,
                           verify_session_path]
      end

      context "user has mfa set to weak level" do
        setup do
          @seed = ROTP::Base32.random_base32
          @user.enable_totp!(@seed, :ui_only)
        end

        should "redirect user back to mfa_redirect_uri after successful mfa setup" do
          @redirect_paths.each do |path|
            session[:mfa_redirect_uri] = path
            put :update, params: { level: "ui_and_api" }
            put :otp_update, params: { otp: ROTP::TOTP.new(@seed).now }

            assert_redirected_to path
            assert_nil session[:mfa_redirect_uri]
          end
        end

        should "not redirect user back to mfa_redirect_uri after failed mfa setup, but mfa_redirect_uri unchanged" do
          @redirect_paths.each do |path|
            session[:mfa_redirect_uri] = path
            put :update, params: { level: "ui_and_api" }
            put :otp_update, params: { otp: "12345" }

            assert_redirected_to edit_settings_path
            assert_equal path, session[:mfa_redirect_uri]
          end
        end

        should "redirect user back to mfa_redirect_uri after a failed setup + successful setup" do
          @redirect_paths.each do |path|
            session[:mfa_redirect_uri] = path
            put :update, params: { level: "ui_and_api" }
            put :otp_update, params: { otp: "12345" }

            assert_redirected_to edit_settings_path
            put :update, params: { level: "ui_and_api" }
            put :otp_update, params: { otp: ROTP::TOTP.new(@seed).now }

            assert_redirected_to path
            assert_nil session[:mfa_redirect_uri]
          end
        end
      end
    end
  end
end
