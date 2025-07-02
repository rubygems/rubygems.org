require "test_helper"

class PoliciesControllerTest < ActionController::TestCase
  context "when index is requested" do
    setup do
      get :index
    end

    should respond_with :ok
  end

  context "when valid page is requested" do
    setup do
      get :show, params: { policy: "acceptable-use" }
    end

    should respond_with :ok
  end

  context "when invalid page is requested" do
    should "error" do
      assert_raises(ActionController::UrlGenerationError) do
        get :show, params: { policy: "not-found-page" }
      end
    end
  end

  context "when acknowledge is requested" do
    context "without authenticated user" do
      should "redirect to sign in" do
        patch :acknowledge, params: { accept: "1" }

        assert_response :redirect
        assert_redirected_to sign_in_path
      end
    end

    context "with authenticated user" do
      setup do
        @user = create(:user, policies_acknowledged_at: nil)
        sign_in_as(@user)
      end

      should "acknowledge policies and redirect" do
        patch :acknowledge, params: { accept: "1" }

        assert_response :redirect
        @user.reload

        assert_not_nil @user.policies_acknowledged_at
      end
    end
  end

  context "when POST request is made to policy pages" do
    should "return method not allowed for any policy" do
      Gemcutter::POLICY_PAGES.each do |policy|
        post :method_not_allowed, params: { policy: policy }

        assert_response :method_not_allowed
        assert_equal "GET", response.headers["Allow"]
      end
    end
  end
end
