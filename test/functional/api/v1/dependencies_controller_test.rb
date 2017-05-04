require 'test_helper'

class Api::V1::DependenciesControllerTest < ActionController::TestCase
  ## JSON ENDPOINTS:
  # NO GEMS:
  context "On GET to index --> with empty gems param --> JSON" do
    setup do
      get :index, gems: "", format: "json"
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

  # WITH GEMS:
  context "On GET to index --> with gems --> JSON" do
    setup do
      rubygem = create(:rubygem, name: "rails")
      create(:version, number: "1.0.0", rubygem_id: rubygem.id)
      get :index, gems: "rails", format: "json"
    end

    should "return 200" do
      assert_response :success
    end

    should "return body" do
      result = [{
        'name'              => 'rails',
        'number'            => '1.0.0',
        'platform'          => 'ruby',
        'dependencies'      => []
      }]

      assert_equal expected_results(result), JSON.load(response.body)
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
      get :index, gems: "myrails,mybundler", format: "json"
    end

    should "return 200" do
      assert_response :success
    end

    should "return surrogate key header" do
      assert_equal "#{surrogate_key_prefix} gem/myrails gem/mybundler", @response.headers['Surrogate-Key']
    end

    should "return body" do
      result = [
        {
          'name'              => 'myrails',
          'number'            => '1.0.0',
          'platform'          => 'ruby',
          'dependencies'      => []
        },

        {
          'name'              => 'myrails',
          'number'            => '3.0.0',
          'platform'          => 'ruby',
          'dependencies'      => []
        },

        {
          'name'              => 'mybundler',
          'number'            => '2.0.0',
          'platform'          => 'ruby',
          'dependencies'      => []
        }
      ]

      assert_same_elements expected_results(result), JSON.load(response.body)
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
      rubygem = create(:rubygem, name: "testgem")
      @version = create(:version, number: "1.0.0", rubygem_id: rubygem.id)
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
      rubygem = create(:rubygem, name: "testgem")
      create(:version, number: "1.0.0", rubygem_id: rubygem.id)
      get :index, gems: "testgem", format: "marshal"
    end

    should "return 200" do
      assert_response :success
    end

    should "return body" do
      result = [{
        name:              'testgem',
        number:            '1.0.0',
        platform:          'ruby',
        dependencies:      []
      }]

      assert_equal expected_results(result, true), Marshal.load(response.body)
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

  def expected_results(payload, _ = false)
    payload
  end

  def surrogate_key_prefix
    'dependencyapi'
  end
end

class Api::V2::DependenciesControllerTest < Api::V1::DependenciesControllerTest
  tests Api::V2::DependenciesController

  should "be using v2 controller" do
    assert_instance_of Api::V2::DependenciesController, @controller
  end

  def expected_results(payload, symbolize = false)
    payload.map do |obj|
      v2_info = { "required_ruby_version"     => ">= 2.0.0",
                  "required_rubygems_version" => ">= 2.6.3",
                  "checksum"                  => nil }
      v2_info.symbolize_keys! if symbolize
      obj.merge v2_info
    end
  end

  def surrogate_key_prefix
    'dependencyapiv2'
  end
end
