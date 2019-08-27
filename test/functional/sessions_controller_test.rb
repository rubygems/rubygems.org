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
      @encoder = WebAuthn::Encoder.new
      @user = User.new(email_confirmed: true)
      @user.webauthn_handle = @encoder.encode(SecureRandom.random_bytes(64))
      @user.save!(validate: false)
      @fake_client = WebAuthn::FakeClient.new("http://test.host", encoding: :base64url)
      public_key_credential = WebAuthn::PublicKeyCredential.from_create(@fake_client.create)
      @user.webauthn_credentials.create!(
        external_id: public_key_credential.id,
        public_key: @encoder.encode(public_key_credential.public_key),
        nickname: "A nickname",
        sign_count: 0
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
      setup do
        @controller.session[:mfa_user] = @user.handle
        @challenge = SecureRandom.random_bytes(32)
        @controller.session[:webauthn_challenge] = @encoder.encode(@challenge)
      end

      context "when authentication succeeds" do
        setup do
          @sign_count = 1234
          @client_credential = @fake_client.get(challenge: @challenge, sign_count: @sign_count)

          post :webauthn_authentication, params: @client_credential
        end

        should respond_with :success
        should "redirect to the dashboard" do
          assert_equal JSON.parse(response.body)["redirect_path"], "/"
        end

        should "clear user name in session" do
          assert @controller.session[:mfa_user].nil?
        end

        should "make user logged in" do
          assert @controller.request.env[:clearance].signed_in?
        end

        should "update sign count" do
          actual_sign_count = WebauthnCredential.find_by(external_id: @client_credential["id"]).sign_count
          assert_equal @sign_count, actual_sign_count
        end
      end

      context "when authentication fails" do
        setup do
          wrong_challenge = SecureRandom.random_bytes(32)
          @client_credential = @fake_client.get(challenge: wrong_challenge, sign_count: 1)

          post :webauthn_authentication, params: @client_credential
        end

        should set_flash[:error]
        should respond_with :unauthorized
        should "attempt to redirect to sign in page" do
          assert_equal JSON.parse(response.body)["redirect_path"], "/sign_in"
        end

        should "not sign in the user" do
          refute @controller.request.env[:clearance].signed_in?
        end

        should "clear user name in session" do
          assert_nil @controller.session[:mfa_user]
        end

        should "not update sign count" do
          actual_sign_count = WebauthnCredential.find_by(external_id: @client_credential["id"]).sign_count
          assert_equal 0, actual_sign_count
        end
      end

      context "when webauthn user handle is incorrect" do
        setup do
          credentials = @fake_client.get(challenge: @challenge)
          credentials["response"]["userHandle"] = @encoder.encode(SecureRandom.random_bytes(64))

          post :webauthn_authentication, params: credentials
        end

        should respond_with :unauthorized
      end

      context "when sign count is missing" do
        setup do
          @client_credential = @fake_client.get(challenge: @challenge)

          post :webauthn_authentication, params: @client_credential
        end

        should respond_with :success
        should "redirect to the dashboard" do
          assert_equal JSON.parse(response.body)["redirect_path"], "/"
        end

        should "clear user name in session" do
          assert @controller.session[:mfa_user].nil?
        end

        should "make user logged in" do
          assert @controller.request.env[:clearance].signed_in?
        end
      end
    end
  end
end
