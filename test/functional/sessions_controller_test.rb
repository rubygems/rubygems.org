require "test_helper"

class SessionsControllerTest < ActionController::TestCase
  context "when user has mfa enabled" do
    setup do
      @user = User.new(email_confirmed: true, handle: "test")
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
        assert_equal @controller.session[:mfa_user], @user.handle
        assert page.has_content? "Multifactor authentication"
      end
    end

    context "on POST to mfa_create" do
      context "when OTP is correct" do
        setup do
          @controller.session[:mfa_user] = @user.handle
          post :mfa_create, params: { otp: ROTP::TOTP.new(@user.mfa_seed).now }
        end

        should respond_with :redirect
        should redirect_to("the dashboard") { dashboard_path }
        should "clear user name in session" do
          assert_nil @controller.session[:mfa_user]
        end

        should "make user logged in" do
          assert @controller.request.env[:clearance].signed_in?
        end
      end

      context "when OTP is recovery code" do
        setup do
          @controller.session[:mfa_user] = @user.handle
          post :mfa_create, params: { otp: @user.mfa_recovery_codes.first }
        end

        should respond_with :redirect
        should redirect_to("the dashboard") { dashboard_path }
        should "clear user name in session" do
          assert_nil @controller.session[:mfa_user]
        end

        should "make user logged in" do
          assert @controller.request.env[:clearance].signed_in?
        end
      end

      context "when OTP is incorrect" do
        setup do
          wrong_otp = (ROTP::TOTP.new(@user.mfa_seed).now.to_i.succ % 1_000_000).to_s
          post :mfa_create, params: { otp: wrong_otp }
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
    end

    context "when login is an array" do
      setup do
        post :create, params: { session: { who: ["1"], password: "pass" } }
      end

      should respond_with :unauthorized
      should "not sign in the user" do
        refute @controller.request.env[:clearance].signed_in?
      end
    end

    context "when user has old SHA1 password" do
      setup do
        @user = create(:user, encrypted_password: "b35e3b6e1b3021e71645b4df8e0a3c7fd98a95fa")
        get :create, params: { session: { who: @user.handle, password: "pass" } }
      end

      should respond_with :unauthorized
    end
  end

  context "on DELETE to destroy" do
    setup do
      delete :destroy
    end

    should respond_with :redirect
    should redirect_to("login page") { sign_in_path }

    should "sign out the user" do
      refute @controller.request.env[:clearance].signed_in?
    end
  end

  context "on GET to verify" do
    setup do
      rubygem = create(:rubygem)
      session[:redirect_uri] = rubygem_owners_url(rubygem)
    end

    context "when signed in" do
      setup do
        user = create(:user)
        sign_in_as(user)
        get :verify, params: { user_id: user.id }
      end
      should respond_with :success
      should "render password verification form" do
        assert page.has_css? "#verify_password_password"
      end
    end

    context "when not signed in" do
      setup do
        user = create(:user)
        get :verify, params: { user_id: user.id }
      end
      should redirect_to("sign in") { sign_in_path }
    end
  end

  context "on POST to authenticate" do
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
          post :authenticate, params: { user_id: user.id, verify_password: { password: PasswordHelpers::SECURE_TEST_PASSWORD } }
        end
        should redirect_to("redirect uri") { rubygem_owners_path(@rubygem) }
      end
      context "on incorrect password" do
        setup do
          @user = create(:user)
          @rubygem = create(:rubygem)
          sign_in_as(@user)
          session[:redirect_uri] = rubygem_owners_url(@rubygem)
          post :authenticate, params: { user_id: @user.id, verify_password: { password: "wrong password" } }
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
        post :authenticate, params: { user_id: user.id, verify_password: { password: PasswordHelpers::SECURE_TEST_PASSWORD } }
      end
      should redirect_to("sign in") { sign_in_path }
    end
  end
end
