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

  context "on GET to show with bad credentials" do
    setup do
      @user = Factory(:user)
      @request.env["HTTP_AUTHORIZATION"] = "Basic " + 
        Base64::encode64("bad:creds")
      get :show
    end
    should "deny access" do
      assert_response 401
      assert_match "HTTP Basic: Access denied.", @response.body
    end
  end

  context "on GET to show with confirmed user" do
    setup do
      @user = Factory(:email_confirmed_user)
      @request.env["HTTP_AUTHORIZATION"] = "Basic " + 
        Base64::encode64("#{@user.email}:#{@user.password}")
      get :show
    end
    should "render api key" do
      assert_response 200
      assert_equal @user.api_key, @response.body
    end
  end
  
  context "on PUT to reset with signed in user" do
    setup do
      @user = Factory(:email_confirmed_user)
      sign_in_as(@user)
    end
    should "reset the user's api key" do
      assert_changed(@user, :api_key) do
        put :reset
      end
    end
    should "redirect to the profile page" do
      put :reset
      assert_redirected_to profile_path
    end
  end
  
end
