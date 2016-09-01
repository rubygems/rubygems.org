require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  context "on GET to new" do
    setup do
      get :new
    end

    should redirect_to("sign up page") { sign_up_url }
  end

  context "on POST to create" do
    context "when email and password are given" do
      should "create a user" do
        post :create, params: { user: { email: 'foo@bar.com', password: 'secret' } }
        assert User.find_by(email: 'foo@bar.com')
      end
    end

    context "when missing a parameter" do
      should "raises parameter missing" do
        post :create
        assert_response :bad_request
        assert page.has_content?("Request is missing param 'user'")
      end
    end

    context "when extra parameters given" do
      should "create a user if parameters are ok" do
        post :create, params: { user: { email: 'foo@bar.com', password: 'secret', handle: 'foo' } }
        assert_equal "foo", User.where(email: 'foo@bar.com').pluck(:handle).first
      end

      should "create a user but dont assign not valid parameters" do
        post :create, params: { user: { email: 'foo@bar.com', password: 'secret', api_key: 'nonono' } }
        assert_not_equal "nonono", User.where(email: 'foo@bar.com').pluck(:api_key).first
      end
    end
  end
end
