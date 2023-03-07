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

  context "on GET to development login" do
    context "with valid ID" do
      setup do
        @admin_user = create(:admin_github_user)
      end

      should "login into admin" do
        get :development_log_in_as, params: { admin_github_user_id: @admin_user.id }
        assert_response :redirect
        assert_redirected_to "/admin"
      end
    end

    context "with invalid ID" do
      should "not login into admin" do
        get :development_log_in_as, params: { admin_github_user_id: 0 }
        assert_response :not_found
      end
    end
  end
end
