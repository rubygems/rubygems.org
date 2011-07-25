require 'test_helper'

class Api::V1::DownloadsControllerTest < ActionController::TestCase

  context "On GET to index" do
    setup do
      @count = 30_000_000
      stub(Download).count { @count }
      get :index
    end

    should "return the download count" do
      assert_equal @count, @response.body.to_i
    end
  end

  context "On GET to index with JSON" do
    setup do
      @count = 30_000_000
      stub(Download).count { @count }
      get :index, :format => 'json'
    end

    should "return the download count" do
      assert_equal @count, JSON.parse(@response.body)['total']
    end
  end

  context "On GET to index with XML" do
    setup do
      @count = 30_000_000
      stub(Download).count { @count }
      get :index, :format => 'xml'
    end

    should "return the download count" do
      assert_equal @count, Nokogiri.parse(@response.body).root.children[1].children.first.text.to_i
    end
  end

  context "On GET to index with YAML" do
    setup do
      @count = 30_000_000
      stub(Download).count { @count }
      get :index, :format => 'yaml'
    end

    should "return the download count" do
      assert_equal @count, YAML.load(@response.body)[:total]
    end
  end

  def get_show(version, format='json')
    get :show, :id => version.full_name, :format => format
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

    should "have some JSON with the total downloads for version1" do
      get_show(@version1)
      assert_equal 3, JSON.parse(@response.body)['total_downloads']
    end

    should "have some JSON with the downloads for the most recent version of version1" do
      get_show(@version1)
      assert_equal 1, JSON.parse(@response.body)['version_downloads']
    end

    should "have some JSON with the total downloads for version2" do
      get_show(@version2)
      assert_equal 3, JSON.parse(@response.body)['total_downloads']
    end

    should "have some JSON with the downloads for the most recent version of version2" do
      get_show(@version2)
      assert_equal 2, JSON.parse(@response.body)['version_downloads']
    end

    should "have some XML with the total downloads for version1" do
      get_show(@version1, 'xml')
      assert_equal 3, Nokogiri.parse(@response.body).at_css('total-downloads').content.to_i
    end

    should "have some XML with the downloads for the most recent version of version1" do
      get_show(@version1, 'xml')
      assert_equal 1, Nokogiri.parse(@response.body).at_css('version-downloads').content.to_i
    end

    should "have some XML with the total downloads for version2" do
      get_show(@version2, 'xml')
      assert_equal 3, Nokogiri.parse(@response.body).at_css('total-downloads').content.to_i
    end

    should "have some XML with the downloads for the most recent version of version2" do
      get_show(@version2, 'xml')
      assert_equal 2, Nokogiri.parse(@response.body).at_css('version-downloads').content.to_i
    end

    should "have some YAML with the total downloads for version1" do
      get_show(@version1, 'yaml')
      assert_equal 3, YAML.load(@response.body)['total_downloads']
    end

    should "have some YAML with the downloads for the most recent version of version1" do
      get_show(@version1, 'yaml')
      assert_equal 1, YAML.load(@response.body)['version_downloads']
    end

    should "have some YAML with the total downloads for version2" do
      get_show(@version2, 'yaml')
      assert_equal 3, YAML.load(@response.body)['total_downloads']
    end

    should "have some YAML with the downloads for the most recent version of version2" do
      get_show(@version2, 'yaml')
      assert_equal 2, YAML.load(@response.body)['version_downloads']
    end
  end

  context "on GET to show for an unknown gem" do
    setup do
      get :show, :id => "rials", :format => 'json'
    end

    should "return a 404" do
      assert_response :not_found
    end

    should "say gem could not be found" do
      assert_equal "This rubygem could not be found.", @response.body
    end
  end
end
