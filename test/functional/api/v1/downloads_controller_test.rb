require 'test_helper'

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

  context "on GET to show" do
    setup do
      gem = Factory(:rubygem_with_downloads)
      version1 = Factory(:version, :rubygem => gem, :number => '1.0.0')
      version2 = Factory(:version, :rubygem => gem, :number => '2.0.0')

      Download.incr(gem.name, version1.full_name)
      Download.incr(gem.name, version2.full_name)
      Download.incr(gem.name, version2.full_name)

      get :show, :id => gem.name
    end

    should "have some json with the total downloads for the gem" do
      assert_equal 3, JSON.parse(@response.body)['total_downloads']
    end

    should "have some json with the downloads for the most recent version of the gem" do
      assert_equal 2, JSON.parse(@response.body)['latest_version_downloads']
    end
  end
end
