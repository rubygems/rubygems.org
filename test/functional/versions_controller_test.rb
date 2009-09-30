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
      @current_version = Factory(:version)
      @rubygem = @current_version.rubygem
      get :show, :rubygem_id => @rubygem.name, :id => @current_version.number
    end

    should_respond_with :success
    should_render_template "rubygems/show"
    should_assign_to :rubygem
    should_assign_to(:current_version) { @current_version }
    should "render info about the gem" do
      assert_contain @rubygem.name
      assert_contain @current_version.number
      assert_contain @current_version.built_at.to_date.to_formatted_s(:long)
    end
  end

end

