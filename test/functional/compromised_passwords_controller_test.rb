# frozen_string_literal: true

require "test_helper"

class CompromisedPasswordsControllerTest < ActionController::TestCase
  include ActionMailer::TestHelper

  setup do
    @user = create(:user)
  end

  context "on GET to show" do
    context "with valid session" do
      setup do
        @controller.session[:compromised_password_user_id] = @user.id
      end

      should "display password reset info page" do
        get :show

        assert_response :success
        assert_select "span.font-semibold", I18n.t("compromised_passwords.show.heading")
        assert_select "a[href=?]", sign_in_path
      end

      should "not enqueue compromised password reset email on page visit" do
        assert_enqueued_emails 0 do
          get :show
        end

        assert_response :success
      end

      should "not update user confirmation_token on page visit" do
        @user.update!(confirmation_token: "this-is-a-test-token")

        original_token = @user.confirmation_token

        get :show

        assert_equal original_token, @user.reload.confirmation_token
      end
    end

    context "without valid session" do
      should "redirect to sign in when session is missing" do
        get :show

        assert_redirected_to sign_in_path
      end

      should "redirect to sign in when user no longer exists" do
        deleted_user_id = @user.id
        @user.destroy
        @controller.session[:compromised_password_user_id] = deleted_user_id

        get :show

        assert_redirected_to sign_in_path
      end
    end
  end
end
