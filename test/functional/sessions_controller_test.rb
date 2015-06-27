require 'test_helper'

class SessionsControllerTest < ActionController::TestCase
  context "on POST to create" do
    context "when login and password are correct" do
      setup do
        User.expects(:authenticate).with('login', 'pass').returns User.new
        post :create, :session => { :who => 'login', :password => 'pass' }
      end

      should respond_with :redirect
      should redirect_to('the dashboard') { dashboard_url }

      should "sign in the user" do
        assert @controller.signed_in?
      end
    end

    context "when login and password are incorrect" do
      setup do
        User.expects(:authenticate).with('login', 'pass').returns nil
        post :create, :session => { :who => 'login', :password => 'pass' }
      end

      should respond_with :unauthorized
      should render_template 'sessions/new'
      should set_flash.now[:notice]

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

    should "sign out the user" do
      assert !@controller.signed_in?
    end
  end
end
