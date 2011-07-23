require 'test_helper'

class Api::V1::ApiKeysControllerTest < ActionController::TestCase
  #should_route :get, "/api_key", :action => :show
  #should_route :put, "/api_key/reset", :action => :reset

  should "route new paths to new controller" do
    route = {:controller => 'api/v1/api_keys', :action => 'show'}
    assert_recognizes(route, '/api/v1/api_key')

    route = {:controller => 'api/v1/api_keys', :action => 'reset'}
    assert_recognizes(route, :path => '/api/v1/api_key/reset', :method => :put)
  end

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
    should respond_with :success
    should "return API key" do
      assert_equal @user.api_key, @response.body
    end
  end

  context "on GET to show with JSON with confirmed user" do
    setup do
      @user = Factory(:email_confirmed_user)
      @request.env["HTTP_AUTHORIZATION"] = "Basic " +
        Base64::encode64("#{@user.email}:#{@user.password}")
      get :show, :format => 'json'
    end
    should respond_with :success
    should "return API key" do
      response = JSON.parse(@response.body)
      assert_not_nil response
      assert_kind_of Hash, response
      assert_equal @user.api_key, response["rubygems_api_key"]
    end
  end

  context "on GET to show with XML with confirmed user" do
    setup do
      @user = Factory(:email_confirmed_user)
      @request.env["HTTP_AUTHORIZATION"] = "Basic " +
        Base64::encode64("#{@user.email}:#{@user.password}")
      get :show, :format => 'xml'
    end
    should respond_with :success
    should "return API key" do
      response = Nokogiri.parse(@response.body).root
      assert_not_nil response
      assert_kind_of Nokogiri::XML::Element, response
      assert_equal @user.api_key, response.children[1].text
    end
  end

  context "on GET to show with YAML with confirmed user" do
    setup do
      @user = Factory(:email_confirmed_user)
      @request.env["HTTP_AUTHORIZATION"] = "Basic " +
        Base64::encode64("#{@user.email}:#{@user.password}")
      get :show, :format => 'yaml'
    end
    should respond_with :success
    should "return API key" do
      response = YAML.load(@response.body)
      assert_not_nil response
      assert_kind_of Hash, response
      assert_equal @user.api_key, response[:rubygems_api_key]
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
    should "redirect to the edit profile page" do
      put :reset
      assert_redirected_to edit_profile_path
    end
  end

  context "on PUT to reset with no signed in user" do
    setup do
      put :reset
    end
    should "redirect" do
      assert_response :redirect
    end
  end
end
