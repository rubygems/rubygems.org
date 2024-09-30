require "test_helper"

class SessionsControllerTest < ActionController::TestCase
  context "when user has mfa enabled" do
    setup do
      @user = create(:user, email_confirmed: true, handle: "login")
      @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
    end

    context "on POST to create" do
      setup do
        @current_time = Time.utc(2023, 1, 1, 0, 0, 0)
        travel_to @current_time
        freeze_time

        post :create, params: { session: { who: "login", password: PasswordHelpers::SECURE_TEST_PASSWORD } }
      end

      should respond_with :success
      should "save user id in session" do
        assert_equal @controller.session[:mfa_user], @user.id
        assert page.has_content? "Multi-factor authentication"
      end

      should "set mfa_login_started_at in session " do
        assert_equal @current_time, @controller.session[:mfa_login_started_at]
      end

      teardown do
        travel_back
      end
    end

    context "on POST to otp_create" do
      setup do
        @current_time = Time.utc(2023, 1, 1, 0, 0, 0)
        travel_to @current_time
        freeze_time

        post :create, params: { session: { who: "login", password: PasswordHelpers::SECURE_TEST_PASSWORD } }
      end

      context "when OTP is correct" do
        setup do
          @controller.session[:mfa_user] = @user.id
          post :otp_create, params: { otp: ROTP::TOTP.new(@user.totp_seed).now }
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
          post :otp_create, params: { otp: @user.new_mfa_recovery_codes.first }
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
          wrong_otp = (ROTP::TOTP.new(@user.totp_seed).now.to_i.succ % 1_000_000).to_s
          post :otp_create, params: { otp: wrong_otp }
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

      context "when mfa code is correct" do
        setup do
          @start_time = @current_time
          @end_time = Time.utc(2023, 1, 1, 0, 2, 0)
          @duration = @end_time - @start_time
          @controller.session[:mfa_user] = @user.id
        end

        should "record duration on successful OTP login" do
          StatsD.expects(:distribution).with("login.mfa.otp.duration", @duration)

          travel_to @end_time do
            post :otp_create, params: { otp: ROTP::TOTP.new(@user.totp_seed).now }
          end
        end

        should "record duration on successful recovery code login" do
          StatsD.expects(:distribution).with("login.mfa.otp.duration", @duration)

          travel_to @end_time do
            post :otp_create, params: { otp: @user.new_mfa_recovery_codes.first }
          end
        end
      end

      teardown do
        travel_back
      end
    end

    context "when OTP is correct but session expired" do
      setup do
        post :create, params: { session: { who: "login", password: PasswordHelpers::SECURE_TEST_PASSWORD } }

        travel 30.minutes

        post :otp_create, params: { otp: ROTP::TOTP.new(@user.totp_seed).now }
      end

      should set_flash.now[:notice]
      should respond_with :unauthorized

      should "clear mfa_expires_at" do
        assert_nil @controller.session[:mfa_expires_at]
      end

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

    context "when no mfa_expires_at session is present" do
      setup do
        @controller.session[:mfa_user] = @user.id

        post :otp_create, params: { otp: ROTP::TOTP.new(@user.totp_seed).now }
      end

      should respond_with :unauthorized

      should "not sign in the user" do
        refute_predicate @controller.request.env[:clearance], :signed_in?
      end

      should "display the error message" do
        assert page.has_content? "Your login page session has expired."
      end
    end

    context "when mfa session is missing mfa_user" do
      setup do
        @controller.session[:mfa_expires_at] = 15.minutes.from_now.to_s

        post :otp_create, params: { otp: ROTP::TOTP.new(@user.totp_seed).now }
      end

      should respond_with :unauthorized

      should "not sign in the user" do
        refute_predicate @controller.request.env[:clearance], :signed_in?
      end

      should "display the error message" do
        assert page.has_content? "Your login page session has expired."
      end
    end
  end

  context "on POST to create" do
    context "when login and password are correct" do
      setup do
        @user = create(:user, handle: "login")
        @controller.session[:mfa_expires_at] = 15.minutes.from_now.to_s
      end

      context "when mfa is not recommended" do
        setup do
          post :create, params: { session: { who: "login", password: PasswordHelpers::SECURE_TEST_PASSWORD } }
        end

        should respond_with :redirect
        should redirect_to("the dashboard") { dashboard_path }

        should "sign in the user" do
          assert_predicate @controller.request.env[:clearance], :signed_in?
        end

        should "set security device notice" do
          expected_notice = "🎉 We now support security devices! Improve your account security by " \
                            "<a href=\"/settings/edit#security-device\">setting up</a> a new device. " \
                            "<a href=\"https://blog.rubygems.org/2023/08/03/level-up-using-security-devices.html\">Learn more</a>!"

          assert_equal expected_notice, flash[:notice_html]
          assert_nil flash[:notice]
        end
      end

      context "when mfa is recommended" do
        setup do
          User.any_instance.stubs(:mfa_recommended?).returns true
        end

        context "when mfa is disabled" do
          setup do
            post :create, params: { session: { who: "login", password: PasswordHelpers::SECURE_TEST_PASSWORD } }
          end

          should respond_with :redirect
          should redirect_to("the mfa setup page") { new_totp_path }

          should "set notice flash" do
            expected_notice = "For protection of your account and your gems, we encourage you to set up multi-factor authentication. " \
                              "Your account will be required to have MFA enabled in the future."

            assert_equal expected_notice, flash[:notice]
            assert_nil flash[:notice_html]
          end
        end

        context "when mfa is enabled" do
          setup do
            @controller.session[:mfa_login_started_at] = Time.now.utc.to_s
            @controller.session[:mfa_user] = @user.id
          end

          context "on `ui_only` level" do
            setup do
              @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
              post :otp_create, params: { otp: ROTP::TOTP.new(@user.totp_seed).now }
            end

            should respond_with :redirect
            should redirect_to("the settings page") { edit_settings_path }

            should "set notice flash" do
              expected_notice = "For protection of your account and your gems, we encourage you to change your MFA level " \
                                "to \"UI and gem signin\" or \"UI and API\". Your account will be required to have MFA enabled " \
                                "on one of these levels in the future."

              assert_equal expected_notice, flash[:notice]
              assert_nil flash[:notice_html]
            end
          end

          context "on `ui_and_gem_signin` level" do
            setup do
              @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_gem_signin)
              post :otp_create, params: { otp: ROTP::TOTP.new(@user.totp_seed).now }
            end

            should respond_with :redirect
            should redirect_to("the dashboard") { dashboard_path }
          end

          context "on `ui_and_api` level" do
            setup do
              @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
              post :otp_create, params: { otp: ROTP::TOTP.new(@user.totp_seed).now }
            end

            should respond_with :redirect
            should redirect_to("the dashboard") { dashboard_path }
          end
        end
      end
    end

    context "when login and password are incorrect" do
      setup do
        post :create, params: { session: { who: "login", password: "incorrectpassword" } }
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

    context "when login params are invalid" do
      setup do
        post :create, params: { session: { who: ["1"], password: PasswordHelpers::SECURE_TEST_PASSWORD } }
      end

      should respond_with :bad_request

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
        assert page.has_button?("Authenticate")
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
        assert_not_nil session[:webauthn_authentication]["challenge"]
      end

      should "set mfa_user" do
        assert_equal @user.id, session[:mfa_user]
      end

      should "have recovery code form if user has recovery codes" do
        assert page.has_content?("Multi-factor authentication")
        assert page.has_content?("Recovery code")
        assert page.has_button?("Authenticate")
      end

      should "not have mfa forms and have webauthn credentials form" do
        assert page.has_content?("Multi-factor authentication")
        assert_not page.has_field?("OTP code")
        assert page.has_button?("Authenticate with security device")
      end

      should "not set security device notice" do
        assert_nil flash[:notice_html]
      end
    end

    context "when user has webauthn credentials but no recovery code" do
      setup do
        @user = create(:user)
        create(:webauthn_credential, user: @user)
        @user.new_mfa_recovery_codes = nil
        @user.mfa_hashed_recovery_codes = []
        @user.save!
        post(
          :create,
          params: { session: { who: @user.handle, password: @user.password } }
        )
      end

      should respond_with :ok

      should "set webauthn authentication" do
        assert_not_nil session[:webauthn_authentication]["challenge"]
      end

      should "set mfa_user" do
        assert_equal @user.id, session[:mfa_user]
      end

      should "not have mfa forms and have webauthn credentials form" do
        assert page.has_content?("Multi-factor authentication")
        assert_not page.has_field?("OTP code")
        assert_not page.has_content?("Recovery code")
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
        assert_not_nil session[:webauthn_authentication]["challenge"]
      end

      should "set mfa_user" do
        assert_equal @user.id, session[:mfa_user]
      end

      should "have mfa forms and webauthn credentials form" do
        assert page.has_content?("multi-factor authentication")
        assert page.has_field?("OTP or recovery code")
        assert page.has_button?("Authenticate")
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

  context "on GET to new" do
    setup do
      get :new
    end

    should "render sign-in form" do
      assert_text "Sign in"
      assert_selector "input[type=password][autocomplete=current-password]"
    end
  end

  context "on GET to verify" do
    setup do
      rubygem = create(:rubygem)
      session[:redirect_uri] = rubygem_owners_url(rubygem.slug)
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
        assert page.has_css? "input[type=password][autocomplete=current-password]"
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
      session[:redirect_uri] = rubygem_owners_url(rubygem.slug)
    end

    context "when signed in" do
      setup do
        @user = create(:user)
        @rubygem = create(:rubygem)
        sign_in_as(@user)
        session[:redirect_uri] = rubygem_owners_url(@rubygem.slug)
      end

      context "on correct password" do
        setup do
          post :authenticate, params: { user_id: @user.id, verify_password: { password: PasswordHelpers::SECURE_TEST_PASSWORD } }
        end
        should redirect_to("redirect uri") { rubygem_owners_path(@rubygem.slug) }
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

  context "on POST to webauthn_create" do
    setup do
      @user = create(:user)
      @webauthn_credential = create(:webauthn_credential, user: @user)
      login_to_session_with_webauthn
    end

    context "when providing correct credentials" do
      context "redirect to dashboard" do
        setup do
          verify_challenge
        end

        should redirect_to :dashboard
      end

      should "log in the user" do
        verify_challenge

        assert_predicate @controller.request.env[:clearance], :signed_in?
      end

      should "record mfa login duration" do
        start_time = Time.utc(2023, 1, 1, 0, 0, 0)
        end_time = Time.utc(2023, 1, 1, 0, 2, 0)
        duration = end_time - start_time

        StatsD.expects(:distribution).with("login.mfa.webauthn.duration", duration)

        travel_to start_time do
          login_to_session_with_webauthn
        end

        travel_to end_time do
          verify_challenge
        end
      end

      should "clear session" do
        verify_challenge

        assert_nil @controller.session[:mfa_expires_at]
        assert_nil @controller.session[:mfa_login_started_at]
        assert_nil @controller.session[:mfa_user]
        assert_nil @controller.session[:webauthn_authentication]
      end
    end

    context "when not providing credentials" do
      setup do
        @existing_webauthn = @controller.session[:webauthn_authentication]
        post(
          :webauthn_create,
          format: :html
        )
      end

      should respond_with :unauthorized

      should "set flash notice" do
        assert_equal "Credentials required", flash[:notice]
      end

      should "render sign in page" do
        assert_template "sessions/new"
        refute_nil @controller.session[:webauthn_authentication]
        refute_equal @existing_webauthn, @controller.session[:webauthn_authentication]
      end

      should "clear session" do
        assert_nil @controller.session[:mfa_expires_at]
        assert_nil @controller.session[:mfa_login_started_at]
        assert_nil @controller.session[:mfa_user]
      end
    end

    context "when providing wrong credentials" do
      setup do
        @existing_webauthn = @controller.session[:webauthn_authentication]
        @wrong_challenge = SecureRandom.hex
        post(
          :webauthn_create,
          params: {
            credentials:
              WebauthnHelpers.get_result(
                client: @client,
                challenge: @wrong_challenge
              )
          },
          format: :html
        )
      end

      should respond_with :unauthorized

      should "set flash notice" do
        assert_equal "WebAuthn::ChallengeVerificationError", flash[:notice]
      end

      should "render sign in page" do
        assert_template "sessions/new"
        refute_nil @controller.session[:webauthn_authentication]
        refute_equal @existing_webauthn, @controller.session[:webauthn_authentication]
      end

      should "clear session" do
        assert_nil @controller.session[:mfa_expires_at]
        assert_nil @controller.session[:mfa_login_started_at]
        assert_nil @controller.session[:mfa_user]
      end
    end

    context "when providing credentials but the session expired" do
      setup do
        travel 30.minutes
        @existing_webauthn = @controller.session[:webauthn_authentication]

        post(
          :webauthn_create,
          params: {
            credentials:
              WebauthnHelpers.get_result(
                client: @client,
                challenge: @challenge
              )
          },
          format: :html
        )
      end

      should respond_with :unauthorized

      should "clear session" do
        assert_nil @controller.session[:mfa_expires_at]
        assert_nil @controller.session[:mfa_login_started_at]
        assert_nil @controller.session[:mfa_user]
      end

      should "not sign in the user" do
        refute_predicate @controller.request.env[:clearance], :signed_in?
      end

      should "set flash notice" do
        assert_equal "Your login page session has expired.", flash[:notice]
      end

      should "render sign in page" do
        assert_template "sessions/new"
        refute_nil @controller.session[:webauthn_authentication]
        refute_equal @existing_webauthn, @controller.session[:webauthn_authentication]
      end
    end
  end

  context "when user owns a gem with more than MFA_REQUIRED_THRESHOLD downloads" do
    setup do
      @user = create(:user)
      sign_in_as(@user)
      @rubygem = create(:rubygem)
      session[:redirect_uri] = rubygem_owners_url(@rubygem.slug)
      create(:ownership, rubygem: @rubygem, user: @user)
      GemDownload.increment(
        Rubygem::MFA_REQUIRED_THRESHOLD + 1,
        rubygem_id: @rubygem.id
      )
    end

    context "user has mfa disabled" do
      context "on GET to verify" do
        setup { get :verify, params: { user_id: @user.id } }

        should redirect_to("the edit settings page") { edit_settings_path }

        should "set mfa_redirect_uri" do
          assert_equal verify_session_path, session[:mfa_redirect_uri]
        end
      end

      context "on POST to authenticate" do
        setup { post :authenticate, params: { user_id: @user.id, verify_password: { password: PasswordHelpers::SECURE_TEST_PASSWORD } } }

        should redirect_to("the edit settings page") { edit_settings_path }

        should "set mfa_redirect_uri" do
          assert_equal authenticate_session_path, session[:mfa_redirect_uri]
        end
      end
    end

    context "user has mfa set to weak level" do
      setup do
        @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
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
        @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
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

        should redirect_to("redirect uri") { rubygem_owners_path(@rubygem.slug) }
      end
    end
  end

  private

  def login_to_session_with_webauthn
    post(
      :create,
      params: { session: { who: @user.handle, password: @user.password } }
    )
    @challenge = session[:webauthn_authentication]["challenge"]
    @origin = WebAuthn.configuration.origin
    @rp_id = URI.parse(@origin).host
    @client = WebAuthn::FakeClient.new(@origin, encoding: false)
    WebauthnHelpers.create_credential(
      webauthn_credential: @webauthn_credential,
      client: @client
    )
  end

  def verify_challenge
    post(
      :webauthn_create,
      params: {
        credentials:
          WebauthnHelpers.get_result(
            client: @client,
            challenge: @challenge
          )
      },
      format: :html
    )
  end
end
