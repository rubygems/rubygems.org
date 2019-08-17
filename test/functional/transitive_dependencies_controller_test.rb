require "test_helper"

class TransitiveDependenciesControllerTest < ActionController::TestCase
  context "GET to show" do
    setup do
      @latest_version = create(:version)
      @rubygem = @latest_version.rubygem

      @rubygem_two = create(:rubygem)

      ["1.0.2", "2.4.3", "4.5.6"].map do |ver_number|
        FactoryBot.create(:version, number: ver_number, rubygem: @rubygem_two)
      end

      @latest_version.dependencies << create(:dependency,
        requirements: "<= 4.0.0",
        scope: :runtime,
        rubygem: @rubygem_two)

      @rubygem_three = create(:rubygem)
      FactoryBot.create(:version, number: "1.2.3", rubygem: @rubygem_three)

      @latest_version.dependencies << create(:dependency,
        requirements: ">= 0",
        scope: :development,
        rubygem: @rubygem_three)

      get :show, params: { rubygem_id: @rubygem.name, version_id: @latest_version.number, format: "json" }
      @response = JSON.parse(@response.body)
    end

    should respond_with :success
    should "return json with valid response" do
      assert_equal @response["run_deps"], [[@rubygem_two.name, "2.4.3", "<= 4.0.0"]]
      assert_equal @response["dev_deps"], [[@rubygem_three.name, "1.2.3", ">= 0"]]
    end
  end
end
