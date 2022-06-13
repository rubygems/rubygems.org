require "test_helper"

class EmailConfirmationsControllerTest < ActionController::TestCase
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

    context "user has mfa enabled" do
      setup do
        @user.mfa_ui_only!
        get :update, params: { token: @user.confirmation_token }
      end

      should respond_with :success
      should "display otp form" do
        assert page.has_content?("Multi-factor authentication")
      end
    end
  end

  context "on POST to mfa_update" do
    context "user has mfa enabled" do
      setup do
        @user = create(:user)
        @user.enable_mfa!(ROTP::Base32.random_base32, :ui_only)
      end

      context "when OTP is correct" do
        setup do
          post :mfa_update, params: { token: @user.confirmation_token, otp: ROTP::TOTP.new(@user.mfa_seed).now }
        end

        should redirect_to("the homepage") { root_url }
        should "should confirm user account" do
          assert @user.email_confirmed
        end
        should "sign in user" do
          assert cookies[:remember_token]
        end
      end

      context "when OTP is incorrect" do
        setup do
          post :mfa_update, params: { token: @user.confirmation_token, otp: "incorrect" }
        end

        should respond_with :unauthorized
        should "alert about otp being incorrect" do
          assert_equal "Your OTP code is incorrect.", flash[:alert]
        end
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
        post :create, params: { email_confirmation: { email: "foo@bar.com" } }
        Delayed::Worker.new.work_off
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
        Mailer.expects(:email_confirmation).times(0)
        post :create, params: { email_confirmation: { email: "someone@else.com" } }
        Delayed::Worker.new.work_off
      end
    end
  end

  context "on POST to unconfirmed" do
    context "user is not signed in" do
      should "not send confirmation mail" do
        Mailer.expects(:email_reset).times(0)
        post :unconfirmed
        Delayed::Worker.new.work_off
      end

      should "redirect to sign in page" do
        post :unconfirmed

        assert_redirected_to sign_in_path
        assert_equal "Please sign in to continue.", flash[:alert]
      end
    end

    context "user is signed in" do
      setup do
        @user = create(:user, confirmation_token: "something")
        sign_in_as(@user)
      end

      should "regenerate confirmation token" do
        post :unconfirmed
        assert_not_equal "something", @user.reload.confirmation_token
      end

      should "send confirmation mail" do
        Mailer.expects(:email_reset).times(1)
        post :unconfirmed
        Delayed::Worker.new.work_off
      end

      should "set success flash and redirect to edit path" do
        post :unconfirmed
        assert_redirected_to edit_profile_path
        expected_notice = "You will receive an email within the next few minutes. It contains instructions for confirming your new email address."
        assert_equal expected_notice, flash[:notice]
      end
    end
  end
end
