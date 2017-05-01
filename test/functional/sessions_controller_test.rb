require 'test_helper'

class SessionsControllerTest < ActionController::TestCase
  context "on POST to create" do
    context "when login and password are correct" do
      setup do
        user = User.new(email_confirmed: true)
        User.expects(:authenticate).with('login', 'pass').returns user
        post :create, params: { session: { who: 'login', password: 'pass' } }
      end

      should respond_with :redirect
      should redirect_to('the dashboard') { dashboard_url }

      should "sign in the user" do
        assert @controller.request.env[:clearance].signed_in?
      end
    end

    context "when login and password are incorrect" do
      setup do
        User.expects(:authenticate).with('login', 'pass')
        post :create, params: { session: { who: 'login', password: 'pass' } }
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
        post :create, params: { session: { who: ['1'], password: 'pass' } }
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
    should redirect_to('login page') { sign_in_url }

    should "sign out the user" do
      refute @controller.request.env[:clearance].signed_in?
    end
  end
end
