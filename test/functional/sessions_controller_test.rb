require "test_helper"
require "webauthn/fake_client"
require "securerandom"

class SessionsControllerTest < ActionController::TestCase
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
          assert @controller.session[:mfa_user].nil?
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
          assert @controller.session[:mfa_user].nil?
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

  context "when user has webauthn enabled" do
    setup do
      @user = User.new(email_confirmed: true)
      @user.save!(validate: false)
      @encoder = WebAuthn::Encoder.new
      @fake_client = WebAuthn::FakeClient.new("http://test.host", encoding: :base64url)
      public_key_credential = WebAuthn::PublicKeyCredential.from_create(@fake_client.create)
      @user.webauthn_credentials.create!(
        external_id: public_key_credential.id,
        public_key: @encoder.encode(public_key_credential.public_key),
        nickname: "A nickname"
      )
    end

    context "on POST to create" do
      setup do
        User.expects(:authenticate).with("login", "pass").returns @user
        post :create, params: { session: { who: "login", password: "pass" } }
      end

      should respond_with :success
      should "save user name in session" do
        assert @controller.session[:mfa_user] == @user.handle
        assert page.has_content? "WebAuthn authentication"
      end
      should "allow to sign in using webauthn device" do
        assert page.has_content? "Use your authenticator to sign in"
        assert page.has_button? "Sign in"
      end
    end

    context "on POST to webauthn_authentication" do
      context "when authentication succeeds" do
        setup do
          @controller.session[:mfa_user] = @user.handle

          challenge = SecureRandom.random_bytes(32)
          @controller.session[:webauthn_challenge] = @encoder.encode(challenge)
          client_credential = @fake_client.get(challenge: challenge)

          post :webauthn_authentication, params: client_credential
        end

        should respond_with :success
        should "redirec to the dashboard" do
          assert_equal JSON.parse(response.body)["redirect_path"], "/"
        end
        should "clear user name in session" do
          assert @controller.session[:mfa_user].nil?
        end
        should "make user logged in" do
          assert @controller.request.env[:clearance].signed_in?
        end
      end

      context "when authentication fails" do
        setup do
          @controller.session[:mfa_user] = @user.handle

          challenge = SecureRandom.random_bytes(32)
          @controller.session[:webauthn_challenge] = @encoder.encode(challenge)
          wrong_challenge = SecureRandom.random_bytes(32)
          client_credential = @fake_client.get(challenge: wrong_challenge)

          post :webauthn_authentication, params: client_credential
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
end
