require "test_helper"

class MultifactorAuthsControllerTest < ActionController::TestCase
  context "when logged in" do
    setup do
      @user = create(:user)
      sign_in_as(@user)
      @request.cookies[:mfa_feature] = "true"
    end

    context "when mfa enabled" do
      setup do
        @user.enable_mfa!(ROTP::Base32.random_base32, :ui_only)
      end

      context "on GET to new mfa" do
        setup do
          get :new
        end

        should respond_with :redirect
        should redirect_to("the settings page") { edit_settings_path }
      end

      context "on POST to create mfa" do
        setup do
          post :create, params: { otp: ROTP::TOTP.new(@user.mfa_seed).now }
        end

        should respond_with :redirect
        should redirect_to("the settings page") { edit_settings_path }
        should "keep mfa enabled" do
          assert_predicate @user.reload, :mfa_enabled?
        end
      end

      context "on PUT to update mfa level" do
        context "on disabling mfa" do
          context "when otp code is correct" do
            setup do
              put :update, params: { otp: ROTP::TOTP.new(@user.mfa_seed).now, level: "disabled" }
            end

            should respond_with :redirect
            should redirect_to("the settings page") { edit_settings_path }
            should "disable mfa" do
              refute_predicate @user.reload, :mfa_enabled?
            end
          end

          context "when otp is recovery code" do
            setup do
              put :update, params: { otp: @user.mfa_recovery_codes.first, level: "disabled" }
            end

            should respond_with :redirect
            should redirect_to("the settings page") { edit_settings_path }
            should "disable mfa" do
              refute_predicate @user.reload, :mfa_enabled?
            end
          end

          context "when otp code is incorrect" do
            setup do
              wrong_otp = (ROTP::TOTP.new(@user.mfa_seed).now.to_i.succ % 1_000_000).to_s
              put :update, params: { otp: wrong_otp, level: "disabled" }
            end

            should respond_with :redirect
            should redirect_to("the settings page") { edit_settings_path }
            should set_flash.to("Your OTP code is incorrect.")
            should "keep mfa enabled" do
              assert_predicate @user.reload, :mfa_enabled?
            end
          end
        end

        context "on updating to ui_only, flash banner is set and mfa level is unchanged" do
          setup do
            @user.mfa_ui_and_api!
            put :update, params: { otp: ROTP::TOTP.new(@user.mfa_seed).now, level: "ui_only" }
          end

          should respond_with :redirect
          should redirect_to("the settings page") { edit_settings_path }
          expected = "Updating multi-factor authentication to \"UI Only\" is no longer supported. Please use \"UI and gem signin\" or \"UI and API\"."
          should "set flash" do
            assert_equal(expected, flash[:error])
          end

          should "mfa level should be same as before" do
            assert_predicate @user.reload, :mfa_ui_and_api?
          end
        end

        context "on updating to ui_and_api" do
          setup do
            put :update, params: { otp: ROTP::TOTP.new(@user.mfa_seed).now, level: "ui_and_api" }
          end

          should respond_with :redirect
          should redirect_to("the settings page") { edit_settings_path }
          should "update make mfa level to mfa_ui_and_api now" do
            assert_predicate @user.reload, :mfa_ui_and_api?
          end
        end

        context "on updating to ui_and_gem_signin" do
          setup do
            put :update, params: { otp: ROTP::TOTP.new(@user.mfa_seed).now, level: "ui_and_gem_signin" }
          end

          should respond_with :redirect
          should redirect_to("the settings page") { edit_settings_path }
          should "update make mfa level to mfa_ui_and_gem_signin now" do
            assert_predicate @user.reload, :mfa_ui_and_gem_signin?
          end
        end
      end
    end

    context "when mfa disabled" do
      setup do
        @user.mfa_disabled!
      end

      context "on POST to create mfa" do
        setup do
          @seed = ROTP::Base32.random_base32
          @controller.session[:mfa_seed] = @seed
        end

        context "when qr-code is not expired" do
          setup do
            @controller.session[:mfa_seed_expire] = Gemcutter::MFA_KEY_EXPIRY.from_now.utc.to_i
            post :create, params: { otp: ROTP::TOTP.new(@seed).now }
          end

          should respond_with :success
          should "show recovery codes" do
            @user.reload.mfa_recovery_codes.each do |code|
              assert page.has_content?(code)
            end
          end
          should "enable mfa" do
            assert_predicate @user.reload, :mfa_enabled?
          end
        end

        context "when qr-code is expired" do
          setup do
            @controller.session[:mfa_seed_expire] = 1.minute.ago
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
          @user.enable_mfa!(@seed, :ui_only)
        end

        should "redirect user back to mfa_redirect_uri after successful mfa setup" do
          @redirect_paths.each do |path|
            session[:mfa_redirect_uri] = path
            post :update, params: { otp: ROTP::TOTP.new(@seed).now, level: "ui_and_api" }
            assert_redirected_to path
            assert_nil session[:mfa_redirect_uri]
          end
        end

        should "not redirect user back to mfa_redirect_uri after failed mfa setup, but mfa_redirect_uri unchanged" do
          @redirect_paths.each do |path|
            session[:mfa_redirect_uri] = path
            post :update, params: { otp: "12345", level: "ui_and_api" }
            assert_redirected_to edit_settings_path
            assert_equal path, session[:mfa_redirect_uri]
          end
        end

        should "redirect user back to mfa_redirect_uri after a failed setup + successful setup" do
          @redirect_paths.each do |path|
            session[:mfa_redirect_uri] = path
            post :update, params: { otp: "12345", level: "ui_and_api" }
            assert_redirected_to edit_settings_path
            post :update, params: { otp: ROTP::TOTP.new(@seed).now, level: "ui_and_api" }
            assert_redirected_to path
            assert_nil session[:mfa_redirect_uri]
          end
        end
      end
    end
  end
end
