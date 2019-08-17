require "test_helper"

class DependenciesControllerTest < ActionController::TestCase
  context "GET to show" do
    setup do
      @latest_version = create(:version, built_at: 1.week.ago, created_at: 1.day.ago)
      @rubygem = @latest_version.rubygem
      @latest_version.dependencies << create(:dependency,
        version: @latest_version,
        rubygem: @rubygem)
      @dependencies = @latest_version.dependencies
      get :show, params: { rubygem_id: @rubygem.name, version_id: @latest_version.number }
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
end
