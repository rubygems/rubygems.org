require "test_helper"

class Api::V1::DependenciesControllerTest < ActionController::TestCase
  ## BROWNOUT / DEPRECATION:
  context "On GET to index -> during brownout range" do
    context "with empty gems param --> JSON" do
      should "return 404" do
        get :index, params: { gems: "" }, format: "json"

        assert_response :not_found
        result = {
          "error" => "The dependency API has gone away. See " \
                     "https://blog.rubygems.org/2023/02/22/dependency-api-deprecation.html " \
                     "for more information",
          "code" => 404
        }

        assert_equal result, JSON.load(response.body)
      end
    end

    context "with gems param and Accept --> JSON" do
      should "return 404" do
        request.headers["Accept"] = "application/json"
        get :index, params: { gems: "testgem" }

        assert_response :not_found
        result = {
          "error" => "The dependency API has gone away. See " \
                     "https://blog.rubygems.org/2023/02/22/dependency-api-deprecation.html " \
                     "for more information",
          "code" => 404
        }

        assert_equal result, JSON.load(response.body)
      end
    end

    context "with gems --> Marshal" do
      should "return 404" do
        get :index, params: { gems: "testgem" }, format: "marshal"

        assert_response :not_found
        assert_equal "The dependency API has gone away. See " \
                     "https://blog.rubygems.org/2023/02/22/dependency-api-deprecation.html " \
                     "for more information",
                     response.body
      end
    end
  end
end
