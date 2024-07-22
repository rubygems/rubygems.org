require "test_helper"

class PagesControllerTest < ActionController::TestCase
  context "when valid page is requested" do
    setup do
      get :show, params: { id: "about" }
    end

    should respond_with :ok
  end

  context "when invalid page is requested" do
    should "error" do
      assert_raises(ActionController::UrlGenerationError) do
        get :show, params: { id: "not-found-page" }
      end
    end
  end
end
