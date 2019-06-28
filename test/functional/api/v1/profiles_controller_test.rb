require "test_helper"

class Api::V1::ProfilesControllerTest < ActionController::TestCase
  setup do
    @user = create(:user)
    sign_in_as(@user)
  end

  def to_json(body)
    JSON.parse body
  end

  def to_yaml(body)
    YAML.safe_load body
  end

  def response_body
    send("to_#{@format}", @response.body)
  end

  %i[json yaml].each do |format|
    context "when using #{format}" do
      setup do
        @format = format
      end

      context "on GET to show with id" do
        setup do
          get :show, params: { id: @user.id }, format: format
        end

        should respond_with :success
      end

      context "on GET to show with handle" do
        setup do
          get :show, params: { id: @user.handle }, format: format
        end

        should respond_with :success
        should "include the user email" do
          assert response_body.key?("email")
          assert_equal @user.email, response_body["email"]
        end
      end

      context "on GET to show when hide email" do
        setup do
          @user.update(hide_email: true)
          get :show, params: { id: @user.handle }, format: format
        end

        should respond_with :success
        should "hide the user email" do
          refute response_body.key?("email")
        end

        should "shows the handle" do
          assert_equal @user.handle, response_body["handle"]
        end
      end
    end
  end
end
