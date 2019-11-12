require "test_helper"

class DependenciesControllerTest < ActionController::TestCase
  setup do
    @latest_version = create(:version, built_at: 1.week.ago, created_at: 1.day.ago)
    @rubygem = @latest_version.rubygem
  end

  def request_endpoint(rubygem, version, format = "html")
    get :show, params: { rubygem_id: rubygem, version_id: version, format: format }
  end

  def render_str_call(scope)
    local_var = { scope: scope, dependencies: @dependencies, gem_name: @rubygem.name }
    ActionController::Base.new.render_to_string(partial: "dependencies/dependencies", formats: [:html], locals: local_var)
  end

  context "GET to show in html" do
    setup do
      @latest_version.dependencies << create(:dependency,
        version: @latest_version,
        rubygem: @rubygem)
      @dependencies = @latest_version.dependencies
      request_endpoint(@rubygem.name, @latest_version.number)
    end

    should respond_with :success
    should "render gem name" do
      assert page.has_content?(@rubygem.name)
    end
    should "render the specified version" do
      assert page.has_content?(@latest_version.number)
    end
    should "render dependencies of gem" do
      @latest_version.dependencies.each do |dependency|
        assert page.has_content?(dependency.rubygem.name)
      end
    end
  end

  context "GET to show in json" do
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

      request_endpoint(@rubygem.name, @latest_version.number, "json")
      @response = JSON.parse(@response.body)
    end

    should respond_with :success
    should "return json with valid response" do
      @dependencies = {
        "runtime" => [[@rubygem_two.name, "2.4.3", "<= 4.0.0"]],
        "development" => [[@rubygem_three.name, "1.2.3", ">= 0"]]
      }
      run = render_str_call("runtime")
      dev = render_str_call("development")
      assert_equal @response["run_html"], run
      assert_equal @response["dev_html"], dev
    end
  end
end
