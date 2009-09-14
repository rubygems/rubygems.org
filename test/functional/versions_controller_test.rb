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
    should_assign_to(:versions) { @rubygem.versions }

    should "show all related versions" do
      @versions.each do |version|
        assert_contain version.number
      end
    end
  end

  #context 'GET to show for existing version' do
  #  setup do
  #    @version = Factory(:version)
  #    get :show, :id => @version.to_param
  #  end

  #  should_respond_with :success
  #  should_render_template :show
  #  should_assign_to :version, :equals => '@version'
  #end

end

