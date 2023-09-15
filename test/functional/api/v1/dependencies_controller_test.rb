require "test_helper"

class Api::V1::DependenciesControllerTest < ActionController::TestCase
  setup do
    travel_to Time.utc(2023, 2, 20)
  end

  ## JSON ENDPOINTS:
  # NO GEMS:
  context "On GET to index --> with empty gems param --> JSON" do
    setup do
      get :index, params: { gems: "" }, format: "json"
    end

    should "return 200" do
      assert_response :success
    end

    should "return an empty body" do
      assert_empty response.body
    end
  end

  context "On GET to index --> with no gems param --> JSON" do
    setup do
      get :index, format: "json"
    end

    should "return 200" do
      assert_response :success
    end

    should "return an empty body" do
      assert_empty response.body
    end
  end

  # INVALID GEMS:
  context "On GET to index --> with hash in gems params --> JSON" do
    setup do
      get :index, params: { gems: { 0 => "a", 1 => "b" } }, format: "json"
    end

    should "return 200" do
      assert_response :success
    end

    should "return an empty body" do
      assert_empty response.body
    end
  end

  # WITH GEMS:
  context "On GET to index --> with gems --> JSON" do
    setup do
      rubygem = create(:rubygem, name: "rails")
      create(:version, number: "1.0.0", rubygem_id: rubygem.id)
      get :index, params: { gems: "rails" }, format: "json"
    end

    should "return 200" do
      assert_response :success
    end

    should "return body" do
      result = [{
        "name"              => "rails",
        "number"            => "1.0.0",
        "platform"          => "ruby",
        "dependencies"      => []
      }]

      assert_equal result, JSON.load(response.body)
    end
  end

  # WITH COMPLEX GEMS:
  context "on GET to index --> with complex gems --> JSON" do
    setup do
      rubygem1 = create(:rubygem, name: "myrails")
      rubygem2 = create(:rubygem, name: "mybundler")
      create(:version, number: "1.0.0", rubygem_id: rubygem1.id)
      create(:version, number: "2.0.0", rubygem_id: rubygem2.id)
      create(:version, number: "3.0.0", rubygem_id: rubygem1.id)
      get :index, params: { gems: "myrails,mybundler" }, format: "json"
    end

    should "return 200" do
      assert_response :success
    end

    should "return surrogate key header" do
      assert_equal "dependencyapi gem/myrails gem/mybundler", @response.headers["Surrogate-Key"]
    end

    should "return body" do
      result = [
        {
          "name"              => "myrails",
          "number"            => "1.0.0",
          "platform"          => "ruby",
          "dependencies"      => []
        },

        {
          "name"              => "myrails",
          "number"            => "3.0.0",
          "platform"          => "ruby",
          "dependencies"      => []
        },

        {
          "name"              => "mybundler",
          "number"            => "2.0.0",
          "platform"          => "ruby",
          "dependencies"      => []
        }
      ]

      assert_same_elements result, JSON.load(response.body)
    end
  end

  # TOO MANY GEMS:
  context "On GET to index --> with gems --> JSON" do
    setup do
      exceed_request_limit = Gemcutter::GEM_REQUEST_LIMIT + 1
      gems = Array.new(exceed_request_limit) { |idx| "rubygem_#{idx}" }.join(",")
      get :index, params: { gems: gems }, format: "json"
    end

    should "return 422" do
      assert_response :unprocessable_entity
    end

    should "return an error body" do
      result = {
        "error" => "Too many gems! (use --full-index instead)",
        "code" => 422
      }

      assert_equal result, JSON.load(response.body)
    end
  end

  ## MARSHAL ENDPOINTS:
  # NO GEMS:
  context "On GET to index --> with no gems --> Marshal" do
    setup do
      rubygem = create(:rubygem, name: "testgem")
      @version = create(:version, number: "1.0.0", rubygem_id: rubygem.id)
      get :index, params: { gems: "" }, format: "marshal"
    end

    should "return 200" do
      assert_response :success
    end

    should "return an empty body" do
      assert_empty response.body
    end
  end

  # INVALID GEMS:
  context "On GET to index --> with array in gems params --> Marshal" do
    setup do
      get :index, params: { gems: %w[a b] }, format: "marshal"
    end

    should "return 200" do
      assert_response :success
    end

    should "return an empty body" do
      assert_empty response.body
    end
  end

  # WITH GEMS:
  context "On GET to index --> with gems --> Marshal" do
    setup do
      rubygem = create(:rubygem, name: "testgem")
      create(:version, number: "1.0.0", rubygem_id: rubygem.id)
      get :index, params: { gems: "testgem" }, format: "marshal"
    end

    should "return 200" do
      assert_response :success
    end

    should "return body" do
      result = [{
        name:              "testgem",
        number:            "1.0.0",
        platform:          "ruby",
        dependencies:      []
      }]

      assert_equal result, Marshal.load(response.body)
    end
  end

  # TOO MANY GEMS:
  context "On GET to index --> with gems --> Marshal" do
    setup do
      exceed_request_limit = Gemcutter::GEM_REQUEST_LIMIT + 1
      gems = Array.new(exceed_request_limit) { |idx| "rubygem_#{idx}" }.join(",")
      get :index, params: { gems: gems }, format: "marshal"
    end

    should "return 422" do
      assert_response :unprocessable_entity
    end

    should "return an error body" do
      assert_equal "Too many gems! (use --full-index instead)", response.body
    end
  end

  ## BROWNOUT / DEPRECATION:
  context "On GET to index -> during brownout range" do
    setup do
      travel_to Time.utc(2023, 3, 29, 0, 5)
    end

    context "with Java user agent" do
      should "return 200" do
        request.user_agent = "Java/1.2.3"
        get :index, params: { gems: "" }, format: "json"

        assert_response :success
        assert_equal "x-dependency-api-allowed", @response.headers["Vary"]
      end
    end

    context "with empty gems param --> JSON" do
      should "return 404" do
        get :index, params: { gems: "" }, format: "json"

        assert_response :not_found
        result = {
          "error" => "The dependency API is going away. See " \
                     "https://blog.rubygems.org/2023/02/22/dependency-api-deprecation.html " \
                     "for more information",
          "code" => 404
        }

        assert_equal result, JSON.load(response.body)
        assert_equal "x-dependency-api-allowed", @response.headers["Vary"]
      end
    end

    context "with gems param and Accept --> JSON" do
      should "return 404" do
        request.headers["Accept"] = "application/json"
        get :index, params: { gems: "testgem" }

        assert_response :not_found
        result = {
          "error" => "The dependency API is going away. See " \
                     "https://blog.rubygems.org/2023/02/22/dependency-api-deprecation.html " \
                     "for more information",
          "code" => 404
        }

        assert_equal result, JSON.load(response.body)
        assert_equal "Accept, x-dependency-api-allowed", @response.headers["Vary"]
      end
    end

    context "with gems --> Marshal" do
      should "return 404" do
        get :index, params: { gems: "testgem" }, format: "marshal"

        assert_response :not_found
        assert_equal "The dependency API is going away. See " \
                     "https://blog.rubygems.org/2023/02/22/dependency-api-deprecation.html " \
                     "for more information",
                     response.body
      end
    end
  end
end
