require 'test_helper'

class EmailConfirmationsControllerTest < ActionController::TestCase
  context 'on GET to update' do
    context 'user exists and token has not expired' do
      setup do
        @user = create(:user)
        get :update, token: @user.confirmation_token
      end

      should 'should confirm user account' do
        assert @user.email_confirmed
      end
      should 'sign in user' do
        assert cookies[:remember_token]
      end
    end

    context 'user does not exist' do
      setup { get :update, token: Clearance::Token.new }

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
        get :update, token: user.confirmation_token
      end

      should 'warn about invalid url' do
        assert_equal flash[:alert], 'Please double check the URL or try submitting it again.'
      end
      should 'not sign in user' do
        refute cookies[:remember_token]
      end
    end
  end
end
