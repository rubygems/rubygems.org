require "test_helper"

class EmailConfirmationsControllerTest < ActionController::TestCase
  include ActionMailer::TestHelper
  include ActiveJob::TestHelper

  context "on GET to update" do
    setup { @user = create(:user) }

    context "user exists and token has not expired" do
      setup do
        get :update, params: { token: @user.confirmation_token }
      end

      should "should confirm user account" do
        assert @user.email_confirmed
      end
      should "sign in user" do
        assert cookies[:remember_token]
      end
    end

    context "user does not exist" do
      setup { get :update, params: { token: Clearance::Token.new } }

      should "warn about invalid url" do
        assert_equal "Please double check the URL or try submitting it again.", flash[:alert]
      end
      should "not sign in user" do
        refute cookies[:remember_token]
      end
    end

    context "array of tokens" do
      setup do
        get :update, params: { token: [@user.confirmation_token, Clearance::Token.new, Clearance::Token.new] }
      end

      should respond_with :bad_request

      should "not sign in user" do
        refute cookies[:remember_token]
      end
    end

    context "token has expired" do
      setup do
        @user.update_attribute("token_expires_at", 2.minutes.ago)
        get :update, params: { token: @user.confirmation_token }
      end

      should "warn about invalid url" do
        assert_equal "Please double check the URL or try submitting it again.", flash[:alert]
      end
      should "not sign in user" do
        refute cookies[:remember_token]
      end
    end

    context "mutliple user has same unconfirmed email" do
      setup do
        @email = "some@email.com"
        @user.update_attribute(:unconfirmed_email, @email)
        @second_user = create(:user, unconfirmed_email: @email)
        get :update, params: { token: @user.confirmation_token }
      end

      should redirect_to("the homepage") { root_url }

      should "confirm email for first user" do
        assert_equal @email, @user.reload.email
      end

      context "second user sends confirmation request" do
        setup do
          get :update, params: { token: @second_user.confirmation_token }
        end

        should "show error to second user on confirmation request and not " do
          assert_equal "Email address has already been taken", flash[:alert]
        end

        should "not confirm email for first user" do
          assert_predicate @second_user, :unconfirmed_email?
          refute_equal @email, @second_user.reload.email
        end
      end
    end

    context "user has totp enabled" do
      setup do
        @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
        get :update, params: { token: @user.confirmation_token }
      end

      should respond_with :success

      should "display otp form" do
        assert page.has_content?("Multi-factor authentication")
        assert page.has_content?("OTP or recovery code")
      end
    end

    context "user has webauthn enabled but no recovery codes" do
      setup do
        create(:webauthn_credential, user: @user)
        @user.mfa_recovery_codes = []
        @user.mfa_hashed_recovery_codes = []
        @user.save!
        get :update, params: { token: @user.confirmation_token }
      end

      should respond_with :success

      should "display webauthn form" do
        assert page.has_content?("Multi-factor authentication")
        assert page.has_button?("Authenticate with security device")
      end

      should "not display recovery code prompt" do
        refute page.has_content?("Recovery code")
      end
    end

    context "user has webauthn enabled and recovery codes" do
      setup do
        create(:webauthn_credential, user: @user)
        get :update, params: { token: @user.confirmation_token }
      end

      should respond_with :success

      should "display webauthn form" do
        assert page.has_content?("Multi-factor authentication")
        assert page.has_button?("Authenticate with security device")
      end

      should "display recovery code prompt" do
        assert page.has_content?("Recovery code")
      end
    end

    context "when user has webauthn and totp" do
      setup do
        @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
        create(:webauthn_credential, user: @user)
        get :update, params: { token: @user.confirmation_token }
      end

      should respond_with :success

      should "display webauthn prompt" do
        assert page.has_button?("Authenticate with security device")
      end

      should "display otp prompt" do
        assert page.has_content?("OTP or recovery code")
      end
    end
  end

  context "on POST to otp_update" do
    context "user has mfa enabled" do
      setup do
        @user = create(:user)
        @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
      end

      context "when OTP is correct" do
        setup do
          get :update, params: { token: @user.confirmation_token, user_id: @user.id }
          post :otp_update, params: { token: @user.confirmation_token, otp: ROTP::TOTP.new(@user.totp_seed).now }
        end

        should redirect_to("the homepage") { root_url }

        should "should confirm user account" do
          assert @user.email_confirmed
        end
        should "clear mfa_expires_at" do
          assert_nil @controller.session[:mfa_expires_at]
        end
      end

      context "when OTP is incorrect" do
        setup do
          get :update, params: { token: @user.confirmation_token, user_id: @user.id }
          post :otp_update, params: { token: @user.confirmation_token, otp: "incorrect" }
        end

        should respond_with :unauthorized

        should "alert about otp being incorrect" do
          assert_equal "Your OTP code is incorrect.", flash[:alert]
        end
      end

      context "when the OTP session is expired" do
        setup do
          get :update, params: { token: @user.confirmation_token, user_id: @user.id }
          travel 16.minutes do
            post :otp_update, params: { token: @user.confirmation_token, otp: ROTP::TOTP.new(@user.totp_seed).now }
          end
        end

        should set_flash.now[:alert]
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
      end
    end
  end

  context "on POST to webauthn_update" do
    setup do
      @user = create(:user)
      @webauthn_credential = create(:webauthn_credential, user: @user)
      get :update, params: { token: @user.confirmation_token, user_id: @user.id }
      @origin = "http://localhost:3000"
      @rp_id = URI.parse(@origin).host
      @client = WebAuthn::FakeClient.new(@origin, encoding: false)
    end

    context "with webauthn enabled" do
      setup do
        @challenge = session[:webauthn_authentication]["challenge"]
        WebauthnHelpers.create_credential(
          webauthn_credential: @webauthn_credential,
          client: @client
        )
        post(
          :webauthn_update,
          params: {
            user_id: @user.id,
            token: @user.confirmation_token,
            credentials:
            WebauthnHelpers.get_result(
              client: @client,
              challenge: @challenge
            )
          }
        )
      end

      should "redirect to root" do
        assert_redirected_to root_url
      end

      should "change the user's email" do
        assert @user.reload.email_confirmed
      end

      should "clear mfa_expires_at" do
        assert_nil @controller.session[:mfa_expires_at]
      end
    end

    context "when not providing credentials" do
      setup do
        post(
          :webauthn_update,
          params: {
            user_id: @user.id,
            token: @user.confirmation_token
          }
        )
      end

      should respond_with :unauthorized

      should "set flash notice" do
        assert_equal "Credentials required", flash[:alert]
      end
    end

    context "when providing wrong credential" do
      setup do
        @wrong_challenge = SecureRandom.hex
        WebauthnHelpers.create_credential(
          webauthn_credential: @webauthn_credential,
          client: @client
        )
        post(
          :webauthn_update,
          params: {
            user_id: @user.id,
            token: @user.confirmation_token,
            credentials:
            WebauthnHelpers.get_result(
              client: @client,
              challenge: @wrong_challenge
            )
          }
        )
      end

      should respond_with :unauthorized

      should "set flash notice" do
        assert_equal "WebAuthn::ChallengeVerificationError", flash[:alert]
      end
      should "still have the webauthn form url" do
        assert_not_nil page.find(".js-webauthn-session--form")[:action]
      end
    end

    context "when webauthn session is expired" do
      setup do
        @challenge = session[:webauthn_authentication]["challenge"]
        WebauthnHelpers.create_credential(
          webauthn_credential: @webauthn_credential,
          client: @client
        )
        travel 16.minutes do
          post(
            :webauthn_update,
            params: {
              user_id: @user.id,
              token: @user.confirmation_token,
              credentials:
              WebauthnHelpers.get_result(
                client: @client,
                challenge: @challenge
              )
            }
          )
        end
      end

      should respond_with :unauthorized
      should set_flash.now[:alert]

      should "clear mfa_expires_at" do
        assert_nil @controller.session[:mfa_expires_at]
      end

      should "render sign in page" do
        assert page.has_content? "Sign in"
      end

      should "not sign in the user" do
        refute_predicate @controller.request.env[:clearance], :signed_in?
      end
    end
  end

  context "on GET to new" do
    setup do
      get :new
    end

    should respond_with :success

    should "display resend instructions" do
      assert page.has_content?("We will email you confirmation link to activate your account.")
    end
  end

  context "on POST to create" do
    context "user exists" do
      setup do
        create(:user, email: "foo@bar.com")
        perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
          post :create, params: { email_confirmation: { email: "foo@bar.com" } }
        end
      end

      should respond_with :redirect
      should redirect_to("the homepage") { root_url }

      should "deliver confirmation email" do
        refute_empty ActionMailer::Base.deliveries
        email = ActionMailer::Base.deliveries.last

        assert_equal ["foo@bar.com"], email.to
        assert_equal ["no-reply@mailer.rubygems.org"], email.from
        assert_equal "Please confirm your email address with RubyGems.org", email.subject
      end

      should "promise to send email if account exists" do
        assert_equal "We will email you confirmation link to activate your account if one exists.", flash[:notice]
      end
    end

    context "invalid params" do
      should "fail friendly" do
        post :create, params: { email_confirmation: "ABC" }

        assert_response 400 # bad status raised by strong params
      end
    end

    context "user does not exist" do
      should "not deliver confirmation email" do
        post :create, params: { email_confirmation: { email: "someone@else.com" } }

        assert_no_enqueued_emails
      end
    end
  end

  context "on POST to unconfirmed" do
    context "user is not signed in" do
      should "not send confirmation mail" do
        Mailer.expects(:email_reset).times(0)
        perform_enqueued_jobs do
          post :unconfirmed
        end
      end

      should "redirect to sign in page" do
        post :unconfirmed

        assert_redirected_to sign_in_path
        assert_equal "Please sign in to continue.", flash[:alert]
      end
    end

    context "user is signed in" do
      setup do
        @user = create(:user, confirmation_token: "something", unconfirmed_email: "new@example.com")
        sign_in_as(@user)
      end

      context "on successful token generation" do
        should "regenerate confirmation token" do
          post :unconfirmed

          assert_not_equal "something", @user.reload.confirmation_token
        end

        should "send confirmation mail" do
          assert_enqueued_email_with Mailer, :email_reset, args: [@user] do
            post :unconfirmed
          end
        end

        should "set success flash and redirect to edit path" do
          post :unconfirmed

          assert_redirected_to edit_profile_path
          expected_notice = "You will receive an email within the next few minutes. It contains instructions for confirming your new email address."

          assert_equal expected_notice, flash[:notice]
        end
      end

      context "on failed confirmation token save" do
        setup do
          post :unconfirmed
          @user.stubs(:save).returns(false)
        end

        should redirect_to("the edit settings page") { edit_profile_path }

        should "set error flash" do
          post :unconfirmed

          assert_equal "Something went wrong. Please try again.", flash[:notice]
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
        end

        context "user has mfa disabled" do
          context "on GET to update" do
            setup do
              get :update, params: { token: @user.confirmation_token }
            end

            should "should confirm user account" do
              assert @user.email_confirmed
            end
          end

          context "on POST to otp_update" do
            setup do
              post :otp_update, params: { token: @user.confirmation_token, otp: "incorrect" }
            end

            should respond_with :unauthorized
          end

          context "on PATCH to unconfirmed" do
            setup { patch :unconfirmed }
            should redirect_to("the edit settings page") { edit_settings_path }

            should "set mfa_redirect_uri" do
              assert_equal unconfirmed_email_confirmations_path, session[:mfa_redirect_uri]
            end
          end

          context "on GET to new" do
            setup { get :new }
            should "not redirect to mfa" do
              assert_response :success
              assert page.has_content? "Resend confirmation email"
            end
          end

          context "on POST to create" do
            setup do
              create(:user, email: "foo@bar.com")
              perform_enqueued_jobs do
                post :create, params: { email_confirmation: { email: "foo@bar.com" } }
              end
            end

            should respond_with :redirect
            should redirect_to("the homepage") { root_url }
          end
        end

        context "user has mfa set to weak level" do
          setup do
            @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
          end

          context "on GET to update" do
            setup do
              get :update, params: { token: @user.confirmation_token }
            end

            should "should confirm user account" do
              assert @user.email_confirmed
            end
          end

          context "on POST to otp_update" do
            setup do
              post :otp_update, params: { token: @user.confirmation_token, otp: "incorrect" }
            end

            should respond_with :unauthorized
          end

          context "on PATCH to unconfirmed" do
            setup { patch :unconfirmed }
            should redirect_to("the edit settings page") { edit_settings_path }

            should "set mfa_redirect_uri" do
              assert_equal unconfirmed_email_confirmations_path, session[:mfa_redirect_uri]
            end
          end

          context "on GET to new" do
            setup { get :new }
            should "not redirect to mfa" do
              assert_response :success
              assert page.has_content? "Resend confirmation email"
            end
          end

          context "on POST to create" do
            setup do
              create(:user, email: "foo@bar.com")
              perform_enqueued_jobs do
                post :create, params: { email_confirmation: { email: "foo@bar.com" } }
              end
            end

            should respond_with :redirect
            should redirect_to("the homepage") { root_url }
          end
        end

        context "user has MFA set to strong level, expect normal behaviour" do
          setup do
            @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
          end

          context "on GET to update" do
            setup do
              get :update, params: { token: @user.confirmation_token }
            end

            should "should confirm user account" do
              assert @user.email_confirmed
            end
          end

          context "on POST to otp_update" do
            setup do
              post :otp_update, params: { token: @user.confirmation_token, otp: "incorrect" }
            end

            should respond_with :unauthorized
          end

          context "on PATCH to unconfirmed" do
            setup { patch :unconfirmed }
            should redirect_to("edit profile page") { edit_profile_path }
          end

          context "on GET to new" do
            setup { get :new }
            should "not redirect to mfa" do
              assert_response :success
              assert page.has_content? "Resend confirmation email"
            end
          end

          context "on POST to create" do
            setup do
              create(:user, email: "foo@bar.com")
              perform_enqueued_jobs do
                post :create, params: { email_confirmation: { email: "foo@bar.com" } }
              end
            end

            should respond_with :redirect
            should redirect_to("the homepage") { root_url }
          end
        end
      end
    end
  end
end
