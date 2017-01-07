require 'test_helper'

class RecentUploadsControllerTest < ActionController::TestCase
  context "on GET to index" do
    setup do
      @recent_uploads = [create(:version)]

      Version.stubs(:recent_uploads).returns @recent_uploads

      get :index
    end

    should "display 25 recently uploaded gems" do
      assert_received(Version, :recent_uploads) { |subject| subject.with(25) }
    end
  end

  context "on GET to index with no data" do
    setup do
      get :index
    end

    should respond_with :success
  end
end
