require 'test_helper'

class SessionsControllerTest < ActionController::TestCase
  context "when user has mfa enabled" do
    setup do
      @user = User.new(email_confirmed: true)
      @user.enable_mfa!(ROTP::Base32.random_base32, :mfa_login_only)
      @request.cookies[:mfa_feature] = 'true'
    end

    context "on POST to create" do
      setup do
        User.expects(:authenticate).with('login', 'pass').returns @user
        post :create, params: { session: { who: 'login', password: 'pass' } }
      end

      should respond_with :success
      should "save user id in session" do
        assert @controller.session[:mfa_user] == @user.id
      end
    end

    context "on POST to mfa_create" do
      context "when OTP is correct" do
        setup do
          @controller.session[:mfa_user] = @user.id
          post :mfa_create, params: { otp: ROTP::TOTP.new(@user.mfa_seed).now }
        end

        should respond_with :redirect
        should redirect_to('the dashboard') { dashboard_path }
        should "clear user id in session" do
          assert @controller.session[:mfa_user].nil?
        end
      end

      context "when OTP is recovery code" do
        setup do
          @controller.session[:mfa_user] = @user.id
          post :mfa_create, params: { otp: @user.mfa_recovery_codes.first }
        end

        should respond_with :redirect
        should redirect_to('the dashboard') { dashboard_path }
        should "clear user id in session" do
          assert @controller.session[:mfa_user].nil?
        end
      end

      context "when OTP is incorrect" do
        setup do
          wrong_otp = (ROTP::TOTP.new(@user.mfa_seed).now.to_i.succ % 1_000_000).to_s
          post :mfa_create, params: { otp: wrong_otp }
        end

        should respond_with :unauthorized

        should "render sign in page" do
          assert page.has_content? "Sign in"
        end

        should "not sign in the user" do
          refute @controller.request.env[:clearance].signed_in?
        end

        should "clear user id in session" do
          assert_nil @controller.session[:mfa_user]
        end
      end
    end
  end

  context "on POST to create" do
    context "when login and password are correct" do
      setup do
        user = User.new(email_confirmed: true)
        User.expects(:authenticate).with('login', 'pass').returns user
        post :create, params: { session: { who: 'login', password: 'pass' } }
      end

      should respond_with :redirect
      should redirect_to('the dashboard') { dashboard_path }

      should "sign in the user" do
        assert @controller.request.env[:clearance].signed_in?
      end
    end

    context "when login and password are incorrect" do
      setup do
        User.expects(:authenticate).with('login', 'pass')
        post :create, params: { session: { who: 'login', password: 'pass' } }
      end

      should respond_with :unauthorized
      should set_flash.now[:notice]

      should "render sign in page" do
        assert page.has_content? "Sign in"
      end

      should "not sign in the user" do
        refute @controller.request.env[:clearance].signed_in?
      end
    end

    context "when login is an array" do
      setup do
        post :create, params: { session: { who: ['1'], password: 'pass' } }
      end

      should respond_with :unauthorized
      should "not sign in the user" do
        refute @controller.request.env[:clearance].signed_in?
      end
    end
  end

  context "on DELETE to destroy" do
    setup do
      delete :destroy
    end

    should respond_with :redirect
    should redirect_to('login page') { sign_in_path }

    should "sign out the user" do
      refute @controller.request.env[:clearance].signed_in?
    end
  end
end
