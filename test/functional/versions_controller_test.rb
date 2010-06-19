require 'test_helper'

class VersionsControllerTest < ActionController::TestCase

  context 'GET to index' do
    setup do
      @rubygem = Factory(:rubygem)
      @versions = (1..5).map do |version|
        Factory(:version, :rubygem => @rubygem)
      end

      get :index, :rubygem_id => @rubygem.name
    end

    should_respond_with :success
    should_render_template :index
    should_assign_to(:rubygem) { @rubygem }
    should_assign_to(:versions) { @rubygem.reload.versions }

    should "show all related versions" do
      @versions.each do |version|
        assert_contain version.number
      end
    end
  end

  context "On GET to show" do
    setup do
      @latest_version = Factory(:version)
      @rubygem = @latest_version.rubygem
      get :show, :rubygem_id => @rubygem.name, :id => @latest_version.number
    end

    should_respond_with :success
    should_render_template "rubygems/show"
    should_assign_to :rubygem
    should_assign_to(:latest_version) { @latest_version }
    should "render info about the gem" do
      assert_contain @rubygem.name
      assert_contain @latest_version.number
      assert_contain @latest_version.built_at.to_date.to_formatted_s(:long)
    end
  end

  context "On GET to stats" do
    setup do
      @latest_version = Factory(:version)
      @rubygem = @latest_version.rubygem
      get :stats, :rubygem_id => @rubygem.name, :id => @latest_version.slug
    end

    should_respond_with :success
    should_render_template "rubygems/stats"
    should_assign_to :rubygem
    should_assign_to(:latest_version) { @latest_version }
    should_assign_to(:versions) { [@latest_version] }
    should "render info about the gem" do
      assert_contain @rubygem.name
    end
  end

end

