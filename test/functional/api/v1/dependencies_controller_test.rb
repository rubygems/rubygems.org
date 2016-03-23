require 'test_helper'

class Api::V1::DependenciesControllerTest < ActionController::TestCase
  def self.should_respond_to(format)
    should "return #{format.to_s.upcase} with the dependencies" do
      @rubygem = create(:rubygem, name: "rack")
      @version = create(:version, number: "1.0.0", rubygem_id: @rubygem.id)
      get :index, gems: "rack", format: format
    end
  end

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

    should_respond_to(:json) do |body| # (Should have an empty body)
      body.should eq("")
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

    should_respond_to(:json) do |body|
      result = [{
        "name"         => 'rails',
        "number"       => '1.0.0',
        "platform"     => 'ruby',
        "dependencies" => []
      }]
      MultiJson.load(body).should eq(result)
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

    should_respond_to(:json) do |body|
      body.should eq("Too many gems (use --full-index instead)")
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

    should_respond_to(:marshal) do |body| # (Should have an empty body)
      body.should eq("")
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

    should_respond_to(:marshal) do |body|
      result = [{
        name:         'rubygems',
        number:       '1.0.0',
        platform:     'ruby',
        dependencies: []
      }]
      Marshal.load(body).should eq(result)
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

    should_respond_to(:marshal) do |body|
      body.should eq("Too many gems (use --full-index instead)")
    end
  end
end
