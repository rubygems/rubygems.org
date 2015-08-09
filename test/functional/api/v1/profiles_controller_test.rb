require 'test_helper'

class Api::V1::ProfilesControllerTest < ActionController::TestCase
  setup do
    @user = create(:user)
    sign_in_as(@user)
  end

  def self.should_respond_to(format)
    context "on GET to show with id" do
      setup do
        get :show, id: @user.id, format: format
      end

      should respond_with :success
    end

    context "on GET to show with handle" do
      setup do
        get :show, id: @user.handle, format: format
      end

      should respond_with :success
      should "include the user email" do
        response = yield @response.body
        assert response.key?("email")
        assert_equal @user.email, response["email"]
      end
    end

    context "on GET to show when hide email" do
      setup do
        @user.update(hide_email: true)
        get :show, id: @user.handle, format: format
      end

      should respond_with :success
      should "hide the user email" do
        response = yield @response.body
        refute response.key?("email")
      end

      should "shows the handle" do
        response = yield @response.body
        assert_equal @user.handle, response["handle"]
      end
    end
  end

  should_respond_to :json do |body|
    JSON.parse body
  end

  should_respond_to :yaml do |body|
    YAML.load body
  end
end
