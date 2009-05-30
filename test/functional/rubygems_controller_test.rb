require 'test_helper'

class RubygemsControllerTest < ActionController::TestCase
  context "On GET to index" do
    setup do
      @gems = (1..3).map { Factory(:rubygem) }
      get :index
    end

    should_respond_with :success
    should_render_template :index
    should_assign_to :gems
    should "render links" do
      @gems.each do |g|
        assert_contain g.name
        assert_have_selector "a[href='#{rubygem_path(g)}']"
      end
    end
  end
end

