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
end
