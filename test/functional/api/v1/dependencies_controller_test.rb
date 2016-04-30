require 'test_helper'

class Api::V1::DependenciesControllerTest < ActionController::TestCase
  ## JSON ENDPOINTS:
  # NO GEMS:
  context "On GET to index --> with no gems --> JSON" do
    setup do
      @rubygem = create(:rubygem, name: "testgem")
      @version = create(:version, number: "1.0.0", rubygem_id: @rubygem.id)
      get :index, gems: "", format: "json"
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
      @rubygem = create(:rubygem, name: "rails")
      @version = create(:version, number: "1.0.0", rubygem_id: @rubygem.id)
      get :index, gems: "rails", format: "json"
    end

    should "return 200" do
      assert_response :success
    end

    should "return body" do
      result = [{
        "name"         => 'rails',
        "number"       => '1.0.0',
        "platform"     => 'ruby',
        "dependencies" => []
      }]

      assert_equal result, MultiJson.load(response.body)
    end
  end

  # TOO MANY GEMS:
  context "On GET to index --> with gems --> JSON" do
    setup do
      gems = Array.new(300) { create(:rubygem) }.join(',')
      get :index, gems: gems, format: "json"
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
      @rubygem = create(:rubygem, name: "testgem")
      @version = create(:version, number: "1.0.0", rubygem_id: @rubygem.id)
      get :index, gems: "", format: "marshal"
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
      @rubygem = create(:rubygem, name: "testgem")
      @version = create(:version, number: "1.0.0", rubygem_id: @rubygem.id)
      get :index, gems: "testgem", format: "marshal"
    end

    should "return 200" do
      assert_response :success
    end

    should "return body" do
      result = [{
        name:         'testgem',
        number:       '1.0.0',
        platform:     'ruby',
        dependencies: []
      }]

      assert_equal result, Marshal.load(response.body) #.should eq(result)
    end
  end

  # TOO MANY GEMS:
  context "On GET to index --> with gems --> Marshal" do
    setup do
      gems = Array.new(300) { create(:rubygem) }.join(',')
      get :index, gems: gems, format: "marshal"
    end

    should "return 422" do
      assert_response :unprocessable_entity
    end

    should "return an error body" do
      assert_equal "Too many gems! (use --full-index instead)", response.body
    end
  end
end
