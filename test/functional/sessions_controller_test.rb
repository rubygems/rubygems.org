require 'test_helper'

class SessionsControllerTest < ActionController::TestCase
  context "on POST to create" do
    context "when login and password are correct" do
      setup do
        mock(User).authenticate('login', 'pass') { User.new }
        post :create, :session => { :who => 'login', :password => 'pass' }
      end

      should respond_with :redirect
      should redirect_to('the dashboard') { dashboard_url }

      should "set the ssl cookie" do
        assert_not_nil cookies[:ssl]
      end

      should "sign in the user" do
        assert @controller.signed_in?
      end
    end

    context "when login and password are incorrect" do
      setup do
        mock(User).authenticate('login', 'pass') { nil }
        post :create, :session => { :who => 'login', :password => 'pass' }
      end

      should respond_with :unauthorized
      should render_template 'sessions/new'
      should set_the_flash.now[:notice]

      should "not set the ssl cookie" do
        assert_nil cookies[:ssl]
      end

      should "not sign in the user" do
        assert !@controller.signed_in?
      end
    end
  end

  context "on DELETE to destroy" do
    setup do
      delete :destroy
    end

    should respond_with :redirect
    should redirect_to('login page') { sign_in_url }

    should "clear the ssl cookie" do
      assert_nil cookies[:ssl]
    end

    should "sign out the user" do
      assert !@controller.signed_in?
    end
  end
end
