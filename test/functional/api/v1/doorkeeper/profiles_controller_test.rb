require 'test_helper'

class Api::V1::Doorkeeper::ProfilesControllerTest < ActionController::TestCase
  setup do
    @user = create(:user)
    @oauth_token = create(:oauth_access_token, resource_owner_id: @user.id)
    @request.headers["Authorization"] = "Bearer #{@oauth_token.token}"
  end

  def response_body
    JSON.parse @response.body
  end

  context "with a valid oauth access token" do
    context "on GET to show" do
      setup do
        get :show, format: :json
      end

      should respond_with :success
      should "include user :id, :handle, :email and :api_key" do
        assert response_body.key?('id')
        assert_equal @user.id, response_body['id']
        assert response_body.key?('handle')
        assert_equal @user.handle, response_body['handle']
        assert response_body.key?('email')
        assert_equal @user.email, response_body['email']
      end
    end

    context "on GET to show when hide email" do
      setup do
        @user.update(hide_email: true)
        get :show, format: :json
      end

      should respond_with :success
      should "include the user email" do
        assert response_body.key?('email')
        assert_equal @user.email, response_body['email']
      end
    end
  end

  context "with invalid oauth access token" do
    context "on GET to show" do
      setup do
        @request.headers["Authorization"] = "Bearer invalid_access_token"
        get :show, format: :json
      end

      should respond_with :unauthorized
    end
  end
end
