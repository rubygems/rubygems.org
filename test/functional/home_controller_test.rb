require 'test_helper'

class HomeControllerTest < ActionController::TestCase
  context "on GET to index" do
    setup do
      Download.stubs(:count).returns 1_1000_000
      get :index
    end

    should respond_with :success
    should render_template :index

    should "display counts" do
      assert page.has_content?("1,000,000")
    end

    should "load up the downloaded gems count" do
      assert_received(Download, :count)
    end
  end

  should "on GET to index with non html accept header" do
    assert_raises(ActionController::UnknownFormat) do
      @request.env['HTTP_ACCEPT'] = "image/gif, image/x-bitmap, image/jpeg, image/pjpeg"
      get :index
    end
  end
end
