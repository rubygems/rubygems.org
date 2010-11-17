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

  context "On GET to top" do
    setup do
      @rubygem_1 = Factory(:rubygem)
      @version_1 = Factory(:version, :rubygem => @rubygem_1)
      @version_2 = Factory(:version, :rubygem => @rubygem_1)

      @rubygem_2 = Factory(:rubygem)
      @version_3 = Factory(:version, :rubygem => @rubygem_2)

      @rubygem_3 = Factory(:rubygem)
      @version_4 = Factory(:version, :rubygem => @rubygem_3)

      3.times { Download.incr(@rubygem_1.name, @version_1.full_name) }
      2.times { Download.incr(@rubygem_1.name, @version_2.full_name) }
      Download.incr(@rubygem_2.name, @version_3.full_name)

      stub(Download).most_downloaded_today(50){ [[@version_1, 3], [@version_2, 2], [@version_3, 1]] }
      get :top
    end

    should "return the 100 gems with the most downloads" do
      gems = JSON.parse(@response.body)['gems']
      assert_equal 3, gems.length
      assert_equal 3, gems[0][1]
      assert_equal 2, gems[1][1]
      assert_equal 1, gems[2][1]
    end
  end

  def get_show(version)
    get :show, :id => "#{version.full_name}.json"
  end

  context "on GET to show" do
    setup do
      rubygem  = Factory(:rubygem_with_downloads)
      @version1 = Factory(:version, :rubygem => rubygem, :number => '1.0.0')
      @version2 = Factory(:version, :rubygem => rubygem, :number => '2.0.0')

      Download.incr(rubygem.name, @version1.full_name)
      Download.incr(rubygem.name, @version2.full_name)
      Download.incr(rubygem.name, @version2.full_name)
    end

    should "have some json with the total downloads for version1" do
      get_show(@version1)
      assert_equal 3, JSON.parse(@response.body)['total_downloads']
    end

    should "have some json with the downloads for the most recent version of version1" do
      get_show(@version1)
      assert_equal 1, JSON.parse(@response.body)['version_downloads']
    end

    should "have some json with the total downloads for version2" do
      get_show(@version2)
      assert_equal 3, JSON.parse(@response.body)['total_downloads']
    end

    should "have some json with the downloads for the most recent version of version2" do
      get_show(@version2)
      assert_equal 2, JSON.parse(@response.body)['version_downloads']
    end
  end

  context "on GET to show for an unknown gem" do
    setup do
      get :show, :id => "rials"
    end

    should "return a 404" do
      assert_response :not_found
    end

    should "say gem could not be found" do
      assert_equal "This rubygem could not be found.", @response.body
    end
  end
end
