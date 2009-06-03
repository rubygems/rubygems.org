require 'test_helper'

class ApiKeysControllerTest < ActionController::TestCase
  context "on GET to show with no credentials" do
    setup do
      get :show
    end
    should "deny access" do
      assert_response 401
      assert_match "HTTP Basic: Access denied.", @response.body
    end
  end

  context "on GET to show with unconfirmed user" do
    setup do
      @user = Factory(:user)
      @request.env["HTTP_AUTHORIZATION"] = "Basic " + 
        Base64::encode64("#{@user.email}:#{@user.password}")
      get :show
    end
    should "deny access" do
      assert_response 401
      assert_match "HTTP Basic: Access denied.", @response.body
    end
  end

  context "on GET to show with confirmed user" do
  end
end
