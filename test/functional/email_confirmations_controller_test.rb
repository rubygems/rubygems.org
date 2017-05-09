require 'test_helper'

class EmailConfirmationsControllerTest < ActionController::TestCase
  context 'on GET to update' do
    context 'user exists and token has not expired' do
      setup do
        @user = create(:user)
        get :update, params: { token: @user.confirmation_token }
      end

      should 'should confirm user account' do
        assert @user.email_confirmed
      end
      should 'sign in user' do
        assert cookies[:remember_token]
      end
    end

    context 'user does not exist' do
      setup { get :update, params: { token: Clearance::Token.new } }

      should 'warn about invalid url' do
        assert_equal flash[:alert], 'Please double check the URL or try submitting it again.'
      end
      should 'not sign in user' do
        refute cookies[:remember_token]
      end
    end

    context 'token has expired' do
      setup do
        user = create(:user)
        user.update_attribute('token_expires_at', 2.minutes.ago)
        get :update, params: { token: user.confirmation_token }
      end

      should 'warn about invalid url' do
        assert_equal flash[:alert], 'Please double check the URL or try submitting it again.'
      end
      should 'not sign in user' do
        refute cookies[:remember_token]
      end
    end
  end

  context 'on GET to new' do
    setup do
      get :new
    end

    should respond_with :success

    should 'display resend instructions' do
      assert page.has_content?('We will email you confirmation link to activate your account.')
    end
  end

  context 'on POST to create' do
    context 'user exists' do
      setup do
        create(:user, email: 'foo@bar.com')
        post :create, params: { email_confirmation: { email: 'foo@bar.com' } }
        Delayed::Worker.new.work_off
      end

      should respond_with :redirect
      should redirect_to('the homepage') { root_url }

      should 'deliver confirmation email' do
        refute ActionMailer::Base.deliveries.empty?
        email = ActionMailer::Base.deliveries.last
        assert_equal ['foo@bar.com'], email.to
        assert_equal ['no-reply@mailer.rubygems.org'], email.from
        assert_equal 'Please confirm your email address with RubyGems.org', email.subject
      end

      should 'promise to send email if account exists' do
        assert_equal flash[:notice], 'We will email you confirmation link to activate your account if one exists.'
      end
    end

    context 'user does not exist' do
      should 'not deliver confirmation email' do
        Mailer.expects(:email_confirmation).times(0)
        post :create, params: { email_confirmation: { email: 'someone@else.com' } }
        Delayed::Worker.new.work_off
      end
    end
  end
end
