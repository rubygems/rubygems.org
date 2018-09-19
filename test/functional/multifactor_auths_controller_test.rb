require 'test_helper'

class MultifactorAuthsControllerTest < ActionController::TestCase
  context 'when logged in' do
    setup do
      @user = create(:user)
      sign_in_as(@user)
      @request.cookies[:mfa_feature] = 'true'
    end

    context 'when mfa enabled' do
      setup do
        @user.enable_mfa!(ROTP::Base32.random_base32, :mfa_login_only)
      end

      context 'on GET to new mfa' do
        setup do
          get :new
        end

        should respond_with :redirect
        should redirect_to('the profile edit page') { edit_profile_path }
      end

      context 'on POST to create mfa' do
        setup do
          post :create, params: { otp: ROTP::TOTP.new(@user.mfa_seed).now }
        end

        should respond_with :redirect
        should redirect_to('the profile edit page') { edit_profile_path }
        should 'keep mfa enabled' do
          assert @user.reload.mfa_enabled?
        end
      end

      context 'on DELETE to destroy mfa' do
        context 'when otp code is correct' do
          setup do
            delete :destroy, params: { otp: ROTP::TOTP.new(@user.mfa_seed).now }
          end

          should respond_with :redirect
          should redirect_to('the profile edit page') { edit_profile_path }
          should 'disable mfa' do
            refute @user.reload.mfa_enabled?
          end
        end

        context 'when input recovery code' do
          setup do
            delete :destroy, params: { otp: @user.mfa_recovery_codes.first }
          end

          should respond_with :redirect
          should redirect_to('the profile edit page') { edit_profile_path }
          should 'disable mfa' do
            refute @user.reload.mfa_enabled?
          end
        end

        context 'when otp code is incorrect' do
          setup do
            wrong_otp = (ROTP::TOTP.new(@user.mfa_seed).now.to_i.succ % 1_000_000).to_s
            delete :destroy, params: { otp: wrong_otp }
          end

          should set_flash[:error]
          should respond_with :redirect
          should redirect_to('the profile edit page') { edit_profile_path }
          should 'keep mfa enabled' do
            assert @user.reload.mfa_enabled?
          end
        end
      end
    end

    context 'when mfa disabled' do
      setup do
        @user.disable_mfa!
      end

      context 'on POST to create mfa' do
        setup do
          @seed = ROTP::Base32.random_base32
          @controller.session[:mfa_seed] = @seed
        end

        context 'when qr-code is not expired' do
          setup do
            @controller.session[:mfa_seed_expire] = Gemcutter::MFA_KEY_EXPIRY.from_now.utc.to_i
            post :create, params: { otp: ROTP::TOTP.new(@seed).now }
          end

          should respond_with :success
          should 'show recovery codes' do
            @user.reload.mfa_recovery_codes.each do |code|
              assert page.has_content?(code)
            end
          end
          should 'enable mfa' do
            assert @user.reload.mfa_enabled?
          end
        end

        context 'when qr-code is expired' do
          setup do
            @controller.session[:mfa_seed_expire] = 1.minute.ago
            post :create, params: { otp: ROTP::TOTP.new(@seed).now }
          end

          should set_flash[:error]
          should respond_with :redirect
          should redirect_to('the profile edit page') { edit_profile_path }
          should 'keep mfa disabled' do
            refute @user.reload.mfa_enabled?
          end
        end
      end

      context 'on DELETE to destroy mfa' do
        setup do
          delete :destroy
        end

        should respond_with :redirect
        should redirect_to('the profile edit page') { edit_profile_path }
        should 'keep mfa disabled' do
          refute @user.reload.mfa_enabled?
        end
      end
    end
  end
end
