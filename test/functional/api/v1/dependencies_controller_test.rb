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
      create(:version, number: "1.0.0", created_at: Date.new(2016, 05, 24), rubygem_id: rubygem.id)
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
        'rubygems_version'  => '>= 2.6.3',
        'ruby_version'      => '>= 2.0.0',
        'checksum'          => 'b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78',
        'created_at'        => '2016-05-24 00:00:00 +0000',
        'dependencies'      => []
      }]

      assert_equal result, MultiJson.load(response.body)
    end
  end

  # WITH COMPLEX GEMS:
  context "on GET to index --> with complex gems --> JSON" do
    setup do
      rubygem1 = create(:rubygem, name: "myrails")
      rubygem2 = create(:rubygem, name: "mybundler")
      create(:version, number: "1.0.0", created_at: Date.new(2016, 05, 24), rubygem_id: rubygem1.id)
      create(:version, number: "2.0.0", created_at: Date.new(2016, 05, 24), rubygem_id: rubygem2.id)
      create(:version, number: "3.0.0", created_at: Date.new(2016, 05, 24), rubygem_id: rubygem1.id)
      get :index, gems: "myrails,mybundler", format: "json"
    end

    should "return 200" do
      assert_response :success
    end

    should "return body" do
      result = [
        {
          'name'              => 'myrails',
          'number'            => '1.0.0',
          'platform'          => 'ruby',
          'rubygems_version'  => '>= 2.6.3',
          'ruby_version'      => '>= 2.0.0',
          'checksum'          => 'b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78',
          'created_at'        => '2016-05-24 00:00:00 +0000',
          'dependencies'      => []
        },

        {
          'name'              => 'myrails',
          'number'            => '3.0.0',
          'platform'          => 'ruby',
          'rubygems_version'  => '>= 2.6.3',
          'ruby_version'      => '>= 2.0.0',
          'checksum'          => 'b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78',
          'created_at'        => '2016-05-24 00:00:00 +0000',
          'dependencies'      => []
        },

        {
          'name'              => 'mybundler',
          'number'            => '2.0.0',
          'platform'          => 'ruby',
          'rubygems_version'  => '>= 2.6.3',
          'ruby_version'      => '>= 2.0.0',
          'checksum'          => 'b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78',
          'created_at'        => '2016-05-24 00:00:00 +0000',
          'dependencies'      => []
        }
      ]

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
      create(:version, number: "1.0.0", created_at: Date.new(2016, 05, 24), rubygem_id: rubygem.id)
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
        rubygems_version:  '>= 2.6.3',
        ruby_version:      '>= 2.0.0',
        checksum:          'b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78',
        created_at:        "2016-05-24 00:00:00 +0000",
        dependencies:      []
      }]

      assert_equal result, Marshal.load(response.body)
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
