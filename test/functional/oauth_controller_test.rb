require "test_helper"

class OAuthControllerTest < ActionController::TestCase
  context "on GET to create" do
    context "with the wrong provider" do
      setup do
        get :create, params: { provider: :developer }
      end

      should respond_with :not_found
    end

    context "without auth info" do
      setup do
        get :create, params: { provider: :github }
      end

      should respond_with :not_found
    end
  end
end
