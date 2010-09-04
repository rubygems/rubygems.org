require_relative '../../../test_helper'

class Api::V1::DownloadsControllerTest < ActionController::TestCase
  context "On GET to index" do
    setup do
      @count = 30_000_000
      stub(Download).count { @count }
      get :index
    end

    should "have some json with plenty of stats" do
      assert_equal @count, JSON.parse(@response.body)['total']
    end
  end
end
