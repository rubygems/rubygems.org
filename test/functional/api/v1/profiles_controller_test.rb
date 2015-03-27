require 'test_helper'

class Api::V1::ProfilesControllerTest < ActionController::TestCase
  setup do
    @user = create(:user)
    sign_in_as(@user)
  end

  context "on GET to show" do
    setup do
      get :show, id: @user.handle, format: :json
    end

    should respond_with :success
    should "include the user email" do
      json = JSON.parse @response.body
      assert json.key?("email")
      assert_equal @user.email, json["email"]
    end
  end

  context "on GET to show when hide email" do
    setup do
      @user.update(hide_email: true)
      get :show, id: @user.handle, format: :json
    end

    should respond_with :success
    should "hide the user email" do
      json = JSON.parse @response.body
      refute json.key?("email")
    end
  end
end
