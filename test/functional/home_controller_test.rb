require 'test_helper'

class HomeControllerTest < ActionController::TestCase
  context "on GET to index" do
    setup do
      stub(Download).count { 1_000_000 }
      get :index
    end

    should respond_with :success
    should render_template :index

    should "display counts" do
      assert page.has_content?("1,000,000")
    end

    should "load up the downloaded gems count" do
      assert_received(Download) { |subject| subject.count }
    end
  end
end
