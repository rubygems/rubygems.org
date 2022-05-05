require "test_helper"

class DependenciesControllerTest < ActionController::TestCase
  setup do
    @version = create(:version)
    @rubygem = @version.rubygem

    @dep_rubygem = create(:rubygem)

    ["1.0.2", "2.4.3", "4.5.6"].map do |ver_number|
      create(:version, number: ver_number, rubygem: @dep_rubygem)
    end

    create(:dependency,
      requirements: "<= 4.0.0",
      scope: :runtime,
      rubygem: @dep_rubygem,
      version: @version)
  end

  def request_endpoint(rubygem, version, format = "html")
    get :show, params: { rubygem_id: rubygem, version_id: version, format: format }
  end

  def render_str_call(scope, dependencies)
    local_var = { scope: scope, dependencies: dependencies, gem_name: @rubygem.name }
    ActionController::Base.new.render_to_string(partial: "dependencies/dependencies", formats: [:html], locals: local_var)
  end

  context "GET to show in html" do
    setup do
      request_endpoint(@rubygem.name, @version.number)
    end

    should respond_with :success
    should "render gem name" do
      assert page.has_content?(@rubygem.name)
    end
    should "render the specified version" do
      assert page.has_content?(@version.number)
    end
    should "render dependencies of gem" do
      @version.dependencies.each do |dependency|
        assert page.has_content?(dependency.rubygem.name)
      end
    end

    context "with a unresolvable dependency" do
      setup do
        @dependency = create(:dependency, :unresolved, version: @version)
        request_endpoint(@rubygem.name, @version.number)
      end
      should respond_with :success
      should "render gem name" do
        assert page.has_content?(@rubygem.name)
      end
      should "render dependencies of gem" do
        refute page.has_content?(@dependency.name)
      end
    end

    context "with an invalid version that makes a valid gem full name" do
      setup do
        prefix = create(:version, rubygem: build(:rubygem, name: "foo"), number: "0.1.0", platform: "ruby")
        create(:version, rubygem: build(:rubygem, name: "foo-bar"), number: "0.1.0", platform: "ruby")
        request_endpoint(prefix.rubygem.name, "bar-0.1.0")
      end

      should respond_with :not_found
    end
  end

  context "GET to show in json" do
    setup do
      @dep_rubygem_two = create(:rubygem)
      create(:version, number: "1.2.3", rubygem: @dep_rubygem_two)

      create(:dependency,
        requirements: ">= 0",
        scope: :development,
        rubygem: @dep_rubygem_two,
        version: @version)

      request_endpoint(@rubygem.name, @version.slug, "json")
      @response = JSON.parse(@response.body)
    end

    should respond_with :success
    should "return json with valid response" do
      dependencies = {
        "runtime" => [[@dep_rubygem.name, "2.4.3", "<= 4.0.0"]],
        "development" => [[@dep_rubygem_two.name, "1.2.3", ">= 0"]]
      }
      run = render_str_call("runtime", dependencies)
      dev = render_str_call("development", dependencies)
      assert_equal run, @response["run_html"]
      assert_equal dev, @response["dev_html"]
    end
  end
end
