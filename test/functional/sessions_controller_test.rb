require "test_helper"

class SessionsControllerTest < ActionController::TestCase
  include DelayedJobHelpers

  context "when user has mfa enabled" do
    setup do
      @user = User.new(email_confirmed: true)
      @user.enable_mfa!(ROTP::Base32.random_base32, :ui_only)
      @request.cookies[:mfa_feature] = "true"
    end

    context "on POST to create" do
      setup do
        User.expects(:authenticate).with("login", "pass").returns @user
        post :create, params: { session: { who: "login", password: "pass" } }
      end

      should respond_with :success
      should "save user name in session" do
        assert @controller.session[:mfa_user] == @user.handle
        assert page.has_content? "Multifactor authentication"
      end

      should "enqueue challenge requested job" do
        assert_equal Set[Castle::ChallengeRequested], queued_job_classes
      end
    end

    context "on POST to mfa_create" do
      context "when OTP is correct" do
        setup do
          @controller.session[:mfa_user] = @user.handle
          post :mfa_create, params: { otp: ROTP::TOTP.new(@user.mfa_seed).now }
          @expected_job_classes = Set[Castle::ChallengeSucceeded, Castle::LoginSucceeded]
        end

        should respond_with :redirect
        should redirect_to("the dashboard") { dashboard_path }
        should "clear user name in session" do
          assert @controller.session[:mfa_user].nil?
        end

        should "make user logged in" do
          assert @controller.request.env[:clearance].signed_in?
        end

        should "enqueue challenge succeeded and login succeeded jobs" do
          assert_equal @expected_job_classes, queued_job_classes
        end
      end

      context "when OTP is recovery code" do
        setup do
          @controller.session[:mfa_user] = @user.handle
          post :mfa_create, params: { otp: @user.mfa_recovery_codes.first }
          @expected_job_classes = Set[Castle::ChallengeSucceeded, Castle::LoginSucceeded]
        end

        should respond_with :redirect
        should redirect_to("the dashboard") { dashboard_path }
        should "clear user name in session" do
          assert @controller.session[:mfa_user].nil?
        end

        should "make user logged in" do
          assert @controller.request.env[:clearance].signed_in?
        end

        should "enqueue challenge succeeded and login succeeded jobs" do
          assert_equal @expected_job_classes, queued_job_classes
        end
      end

      context "when OTP is incorrect" do
        setup do
          wrong_otp = (ROTP::TOTP.new(@user.mfa_seed).now.to_i.succ % 1_000_000).to_s
          post :mfa_create, params: { otp: wrong_otp }
          @expected_job_classes = Set[Castle::ChallengeFailed, Castle::LoginFailed]
        end

        should set_flash.now[:notice]
        should respond_with :unauthorized

        should "render sign in page" do
          assert page.has_content? "Sign in"
        end

        should "not sign in the user" do
          refute @controller.request.env[:clearance].signed_in?
        end

        should "clear user name in session" do
          assert_nil @controller.session[:mfa_user]
        end

        should "enqueue challenge failed and login failed jobs" do
          assert_equal @expected_job_classes, queued_job_classes
        end
      end
    end
  end

  context "on POST to create" do
    context "when login and password are correct" do
      setup do
        user = User.new(email_confirmed: true)
        User.expects(:authenticate).with("login", "pass").returns user
        post :create, params: { session: { who: "login", password: "pass" } }
      end

      should respond_with :redirect
      should redirect_to("the dashboard") { dashboard_path }

      should "sign in the user" do
        assert @controller.request.env[:clearance].signed_in?
      end

      should "enqueue login succeeded job" do
        assert_equal Set[Castle::LoginSucceeded], queued_job_classes
      end
    end

    context "when login and password are incorrect" do
      setup do
        User.expects(:authenticate).with("login", "pass")
        post :create, params: { session: { who: "login", password: "pass" } }
      end

      should respond_with :unauthorized
      should set_flash.now[:notice]

      should "render sign in page" do
        assert page.has_content? "Sign in"
      end

      should "not sign in the user" do
        refute @controller.request.env[:clearance].signed_in?
      end

      should "enqueue login failed job" do
        assert_equal Set[Castle::LoginFailed], queued_job_classes
      end
    end

    context "when login is an array" do
      setup do
        post :create, params: { session: { who: ["1"], password: "pass" } }
      end

      should respond_with :unauthorized
      should "not sign in the user" do
        refute @controller.request.env[:clearance].signed_in?
      end

      should "enqueue login failed job" do
        assert_equal Set[Castle::LoginFailed], queued_job_classes
      end
    end
  end

  context "on DELETE to destroy" do
    setup do
      delete :destroy
      @expected_job_classes = Set[Castle::LogoutSucceeded]
    end

    should respond_with :redirect
    should redirect_to("login page") { sign_in_path }

    should "sign out the user" do
      refute @controller.request.env[:clearance].signed_in?
    end

    should "enqueue logout succeeded job" do
      assert_equal Set[Castle::LogoutSucceeded], queued_job_classes
    end
  end
end
