require 'test_helper'

class HomeControllerTest < ActionController::TestCase
  context "on GET to index" do
    setup do
      mock(Rubygem).count { 1337 }
      mock(Rubygem).by_created_at(:desc).stub!.limited(5) { [] }
      mock(Version).by_created_at(:desc).stub!.limited(5) { [] }
      mock(Rubygem).by_downloads(:desc).stub!.limited(5) { [] }
      get :index
    end
    should_respond_with :success
    should_render_template :index
    should_assign_to(:count) { 1337 }
    should "display count" do
      assert_contain "1,337"
    end
  end
end
