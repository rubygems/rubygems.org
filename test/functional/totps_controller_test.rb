# frozen_string_literal: true

require "test_helper"

class TotpsControllerTest < ActionController::TestCase
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
            refute_empty @user.mfa_hashed_recovery_codes
          end

          should "flash error" do
            assert_equal "Your OTP code is incorrect.", flash[:error]
          end

          should "not send mfa disabled email" do
            assert_emails 0
          end

          should "not clear mfa_redirect_uri from session" do
            refute_nil session[:mfa_redirect_uri]
          end
        end

        should "track losing the last factor with Datadog AppSec" do
          span = with_appsec_trace { delete :destroy, params: { otp: ROTP::TOTP.new(@user.totp_seed).now } }

          assert_predicate @user.reload, :mfa_disabled?
          assert_equal(
            { "track" => "true", "usr.id" => @user.id.to_s, "mfa.change" => "totp_disabled",
              "mfa.previous_level" => "ui_only", "mfa.level" => "disabled", "mfa.remaining_factors" => "0" },
            appsec_event_tags(span, "mfa.weakened")
          )
        end

        should "not track MFA weakening with Datadog AppSec for an incorrect OTP" do
          span = with_appsec_trace do
            assert_no_changes -> { @user.reload.attributes.slice("totp_seed", "mfa_level", "mfa_hashed_recovery_codes") } do
              delete :destroy, params: { otp: "123456" }
            end
          end

          assert_redirected_to edit_settings_path
          assert_equal "Your OTP code is incorrect.", flash[:error]
          assert_empty appsec_event_tags(span, "mfa.weakened")
        end

        should "still disable TOTP and report the error when Datadog AppSec tracking raises" do
          error = RuntimeError.new("datadog is down")
          Datadog::Kit::AppSec::Events.stubs(:track).raises(error)
          Rails.error.expects(:report).with(error, handled: true)

          delete :destroy, params: { otp: ROTP::TOTP.new(@user.totp_seed).now }

          assert_redirected_to edit_settings_path
          assert_predicate @user.reload, :totp_disabled?
        end

        context "when a webauthn device remains" do
          setup do
            create(:webauthn_credential, user: @user)
          end

          should "track removing one of several factors with Datadog AppSec" do
            span = with_appsec_trace { delete :destroy, params: { otp: ROTP::TOTP.new(@user.totp_seed).now } }

            assert_predicate @user.reload, :totp_disabled?
            assert_equal(
              { "track" => "true", "usr.id" => @user.id.to_s, "mfa.change" => "totp_disabled",
                "mfa.previous_level" => "ui_only", "mfa.level" => "ui_only", "mfa.remaining_factors" => "1" },
              appsec_event_tags(span, "mfa.weakened")
            )
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
  end
end
