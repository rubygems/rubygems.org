require "test_helper"

class SessionsControllerTest < ActionController::TestCase
  context "when user has mfa enabled" do
    setup do
      @user = User.new(email_confirmed: true, handle: "test")
      @user.enable_mfa!(ROTP::Base32.random_base32, :ui_only)
    end

    context "on POST to create" do
      setup do
        User.expects(:authenticate).with("login", "pass").returns @user
        post :create, params: { session: { who: "login", password: "pass" } }
      end

      should respond_with :success
      should "save user name in session" do
        assert_equal @controller.session[:mfa_user], @user.id
        assert page.has_content? "Multi-factor authentication"
      end
    end

    context "on POST to mfa_create" do
      context "when OTP is correct" do
        setup do
          @controller.session[:mfa_user] = @user.id
          post :mfa_create, params: { otp: ROTP::TOTP.new(@user.mfa_seed).now }
        end

        should respond_with :redirect
        should redirect_to("the dashboard") { dashboard_path }
        should "clear user name in session" do
          assert_nil @controller.session[:mfa_user]
        end

        should "make user logged in" do
          assert_predicate @controller.request.env[:clearance], :signed_in?
        end
      end

      context "when OTP is recovery code" do
        setup do
          @controller.session[:mfa_user] = @user.id
          post :mfa_create, params: { otp: @user.mfa_recovery_codes.first }
        end

        should respond_with :redirect
        should redirect_to("the dashboard") { dashboard_path }
        should "clear user name in session" do
          assert_nil @controller.session[:mfa_user]
        end

        should "make user logged in" do
          assert_predicate @controller.request.env[:clearance], :signed_in?
        end
      end

      context "when OTP is incorrect" do
        setup do
          @controller.session[:mfa_user] = @user.id
          wrong_otp = (ROTP::TOTP.new(@user.mfa_seed).now.to_i.succ % 1_000_000).to_s
          post :mfa_create, params: { otp: wrong_otp }
        end

        should set_flash.now[:notice]
        should respond_with :unauthorized

        should "render sign in page" do
          assert page.has_content? "Sign in"
        end

        should "not sign in the user" do
          refute_predicate @controller.request.env[:clearance], :signed_in?
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
        assert_predicate @controller.request.env[:clearance], :signed_in?
      end

      context "when mfa is recommended" do
        setup do
          @user = User.new(email_confirmed: true, handle: "test")
          @user.stubs(:mfa_recommended?).returns true
        end

        context "when mfa is disabled" do
          setup do
            User.expects(:authenticate).with("login", "pass").returns @user
            post :create, params: { session: { who: "login", password: "pass" } }
          end

          should respond_with :redirect
          should redirect_to("the mfa setup page") { new_multifactor_auth_path }

          should "set notice flash" do
            expected_notice = "For protection of your account and your gems, we encourage you to set up multi-factor authentication. " \
                              "Your account will be required to have MFA enabled in the future."
            assert_equal expected_notice, flash[:notice]
          end
        end

        context "when mfa is enabled" do
          setup do
            @controller.session[:mfa_user] = @user.id
            User.expects(:find).with(@user.id).returns @user
          end

          context "on `ui_only` level" do
            setup do
              @user.enable_mfa!(ROTP::Base32.random_base32, :ui_only)
              post :mfa_create, params: { otp: ROTP::TOTP.new(@user.mfa_seed).now }
            end

            should respond_with :redirect
            should redirect_to("the settings page") { edit_settings_path }

            should "set notice flash" do
              expected_notice = "For protection of your account and your gems, we encourage you to change your MFA level " \
                                "to \"UI and gem signin\" or \"UI and API\". Your account will be required to have MFA enabled " \
                                "on one of these levels in the future."

              assert_equal expected_notice, flash[:notice]
            end
          end

          context "on `ui_and_gem_signin` level" do
            setup do
              @user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_gem_signin)
              post :mfa_create, params: { otp: ROTP::TOTP.new(@user.mfa_seed).now }
            end

            should respond_with :redirect
            should redirect_to("the dashboard") { dashboard_path }
          end

          context "on `ui_and_api` level" do
            setup do
              @user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_api)
              post :mfa_create, params: { otp: ROTP::TOTP.new(@user.mfa_seed).now }
            end

            should respond_with :redirect
            should redirect_to("the dashboard") { dashboard_path }
          end
        end
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
        refute_predicate @controller.request.env[:clearance], :signed_in?
      end
    end

    context "when login is an array" do
      setup do
        post :create, params: { session: { who: ["1"], password: "pass" } }
      end

      should respond_with :unauthorized
      should "not sign in the user" do
        refute_predicate @controller.request.env[:clearance], :signed_in?
      end
    end

    context "when user has old SHA1 password" do
      setup do
        @user = create(:user, encrypted_password: "b35e3b6e1b3021e71645b4df8e0a3c7fd98a95fa")
        get :create, params: { session: { who: @user.handle, password: "pass" } }
      end

      should respond_with :unauthorized
    end

    context "when user has mfa enabled" do
      setup do
        @user = create(:user, :mfa_enabled)
        post(
          :create,
          params: { session: { who: @user.handle, password: @user.password } }
        )
      end

      should respond_with :ok

      should "not set webauthn_authentication" do
        assert_nil session[:webauthn_authentication]
      end

      should "set mfa_user" do
        assert_equal @user.id, session[:mfa_user]
      end

      should "have mfa forms and not webauthn credentials form" do
        assert page.has_content?("multi-factor authentication")
        assert page.has_field?("OTP or recovery code")
        assert page.has_button?("Verify code")
      end
    end

    context "when user has webauthn credentials" do
      setup do
        @user = create(:user)
        create(:webauthn_credential, user: @user)
        post(
          :create,
          params: { session: { who: @user.handle, password: @user.password } }
        )
      end

      should respond_with :ok

      should "set webauthn authentication" do
        assert_equal @user.id, session[:webauthn_authentication]["user"]
        assert_not_nil session[:webauthn_authentication]["challenge"]
      end

      should "not set mfa_user" do
        assert_nil session[:mfa_user]
      end

      should "not have mfa forms and have webauthn credentials form" do
        assert page.has_content?("Multi-factor authentication")
        assert_not page.has_field?("OTP code")
        assert_not page.has_field?("Recovery code")
        assert page.has_button?("Authenticate with security device")
      end
    end

    context "when user has mfa enabled and webauthn credentials" do
      setup do
        @user = create(:user, :mfa_enabled)
        create(:webauthn_credential, user: @user)
        post(
          :create,
          params: { session: { who: @user.handle, password: @user.password } }
        )
      end

      should respond_with :ok

      should "set webauthn authentication" do
        assert_equal @user.id, session[:webauthn_authentication]["user"]
        assert_not_nil session[:webauthn_authentication]["challenge"]
      end

      should "set mfa_user" do
        assert_equal @user.id, session[:mfa_user]
      end

      should "have mfa forms and webauthn credentials form" do
        assert page.has_content?("multi-factor authentication")
        assert page.has_field?("OTP or recovery code")
        assert page.has_button?("Verify code")
        assert page.has_button?("Authenticate with security device")
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
      refute_predicate @controller.request.env[:clearance], :signed_in?
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
      setup do
        @user = create(:user)
        @rubygem = create(:rubygem)
        sign_in_as(@user)
        session[:redirect_uri] = rubygem_owners_url(@rubygem)
      end

      context "on correct password" do
        setup do
          post :authenticate, params: { user_id: @user.id, verify_password: { password: PasswordHelpers::SECURE_TEST_PASSWORD } }
        end
        should redirect_to("redirect uri") { rubygem_owners_path(@rubygem) }
      end

      context "on incorrect password" do
        setup do
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

  context "#webauthn_create" do
    context "when verifying the challenge" do
      setup do
        @user = create(:user)
        @webauthn_credential = create(:webauthn_credential, user: @user)
        post(
          :create,
          params: { session: { who: @user.handle, password: @user.password } }
        )
        @challenge = session[:webauthn_authentication]["challenge"]
        @origin = "http://localhost:3000"
        @rp_id = URI.parse(@origin).host
        @client = WebAuthn::FakeClient.new(@origin, encoding: false)
        WebauthnHelpers.create_credential(
          webauthn_credential: @webauthn_credential,
          client: @client
        )
        post(
          :webauthn_create,
          params: {
            credentials:
              WebauthnHelpers.get_result(
                client: @client,
                challenge: @challenge
              )
          },
          format: :json
        )
      end

      should redirect_to :dashboard

      should "log in the user" do
        assert_predicate @controller.request.env[:clearance], :signed_in?
      end
    end

    context "when not providing credentials" do
      setup do
        @user = create(:user)
        @webauthn_credential = create(:webauthn_credential, user: @user)
        post(
          :create,
          params: { session: { who: @user.handle, password: @user.password } }
        )
        post(
          :webauthn_create,
          format: :json
        )
      end

      should respond_with :unauthorized
    end

    context "when providing wrong credentials" do
      setup do
        @user = create(:user)
        @webauthn_credential = create(:webauthn_credential, user: @user)
        post(
          :create,
          params: { session: { who: @user.handle, password: @user.password } }
        )
        @wrong_challenge = SecureRandom.hex
        @origin = "http://localhost:3000"
        @rp_id = URI.parse(@origin).host
        @client = WebAuthn::FakeClient.new(@origin, encoding: false)
        WebauthnHelpers.create_credential(
          webauthn_credential: @webauthn_credential,
          client: @client
        )
        post(
          :webauthn_create,
          params: {
            credentials:
              WebauthnHelpers.get_result(
                client: @client,
                challenge: @wrong_challenge
              )
          },
          format: :json
        )
      end

      should respond_with :unauthorized
    end
  end

  context "when user owns a gem with more than MFA_REQUIRED_THRESHOLD downloads" do
    setup do
      @user = create(:user)
      sign_in_as(@user)
      @rubygem = create(:rubygem)
      session[:redirect_uri] = rubygem_owners_url(@rubygem)
      create(:ownership, rubygem: @rubygem, user: @user)
      GemDownload.increment(
        Rubygem::MFA_REQUIRED_THRESHOLD + 1,
        rubygem_id: @rubygem.id
      )
    end

    context "user has mfa disabled" do
      context "on GET to verify" do
        setup { get :verify, params: { user_id: @user.id } }

        should redirect_to("the setup mfa page") { new_multifactor_auth_path }
        should "set mfa_redirect_uri" do
          assert_equal verify_session_path, session[:mfa_redirect_uri]
        end
      end

      context "on POST to authenticate" do
        setup { post :authenticate, params: { user_id: @user.id, verify_password: { password: PasswordHelpers::SECURE_TEST_PASSWORD } } }

        should redirect_to("the setup mfa page") { new_multifactor_auth_path }
        should "set mfa_redirect_uri" do
          assert_equal authenticate_session_path, session[:mfa_redirect_uri]
        end
      end
    end

    context "user has mfa set to weak level" do
      setup do
        @user.enable_mfa!(ROTP::Base32.random_base32, :ui_only)
      end

      context "on GET to verify" do
        setup { get :verify, params: { user_id: @user.id } }

        should redirect_to("the settings page") { edit_settings_path }
        should "set mfa_redirect_uri" do
          assert_equal verify_session_path, session[:mfa_redirect_uri]
        end
      end

      context "on POST to authenticate" do
        setup { post :authenticate, params: { user_id: @user.id, verify_password: { password: PasswordHelpers::SECURE_TEST_PASSWORD } } }

        should redirect_to("the settings page") { edit_settings_path }
        should "set mfa_redirect_uri" do
          assert_equal authenticate_session_path, session[:mfa_redirect_uri]
        end
      end
    end

    context "user has MFA set to strong level, expect normal behaviour" do
      setup do
        @user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_api)
      end

      context "on GET to verify" do
        setup { get :verify, params: { user_id: @user.id } }

        should respond_with :success
        should "render password verification form" do
          assert page.has_css? "#verify_password_password"
        end
      end

      context "on POST to authenticate" do
        setup { post :authenticate, params: { user_id: @user.id, verify_password: { password: PasswordHelpers::SECURE_TEST_PASSWORD } } }

        should redirect_to("redirect uri") { rubygem_owners_path(@rubygem) }
      end
    end
  end
end
