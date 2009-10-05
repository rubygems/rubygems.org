require 'test_helper'

class HomeControllerTest < ActionController::TestCase
  context "on GET to index" do
    setup do
      @count = 1337
      stub(Rubygem).total_count { @count }
      stub(Rubygem).latest { [] }
      stub(Rubygem).downloaded { [] }
      stub(Version).updated { [] }
      get :index
    end

    should_respond_with :success
    should_render_template :index
    should_assign_to(:count) { @count }
    should_assign_to(:latest)
    should_assign_to(:downloaded)
    should_assign_to(:updated)

    should "display count" do
      assert_contain "1,337"
    end

    should "load up the total count, latest, and most downloaded gems" do
      assert_received(Rubygem) { |subject| subject.total_count }
      assert_received(Rubygem) { |subject| subject.latest }
      assert_received(Rubygem) { |subject| subject.downloaded }
      assert_received(Version) { |subject| subject.updated }
    end
  end
end
