require 'test_helper'

class Api::V1::VersionsControllerTest < ActionController::TestCase
  def get_show(rubygem, format='json')
    get :show, :id => rubygem.name, :format => format
  end

  context "on GET to show" do
    setup do
      @rubygem = Factory(:rubygem)
      Factory(:version, :rubygem => @rubygem, :number => '2.0.0')
      Factory(:version, :rubygem => @rubygem, :number => '1.0.0.pre', :prerelease => true)
      Factory(:version, :rubygem => @rubygem, :number => '3.0.0', :indexed => false)

      @rubygem2 = Factory(:rubygem)
      Factory(:version, :rubygem => @rubygem2, :number => '3.0.0')
      Factory(:version, :rubygem => @rubygem2, :number => '2.0.0')
      Factory(:version, :rubygem => @rubygem2, :number => '1.0.0')
    end

    context "with JSON" do
      should "have some JSON with the list of versions for the first gem" do
        get_show(@rubygem)
        assert_equal 2, JSON.parse(@response.body).size
      end

      should "be ordered by position with prereleases" do
        get_show(@rubygem)
        json = JSON.parse(@response.body)
        assert_equal "2.0.0", json.first["number"]
        assert_equal "1.0.0.pre", json.second["number"]
      end

      should "be ordered by position" do
        get_show(@rubygem2)
        json = JSON.parse(@response.body)
        assert_equal "3.0.0", json.first["number"]
        assert_equal "2.0.0", json.second["number"]
        assert_equal "1.0.0", json.third["number"]
      end

      should "have some JSON with the list of versions for the second gem" do
        get_show(@rubygem2)
        assert_equal 3, JSON.parse(@response.body).size
      end
    end

    context "with XML" do
      should "have some XML with the list of versions for the first gem" do
        get_show(@rubygem, 'xml')
        assert_equal 2, Nokogiri.parse(@response.body).css('version').size
      end

      should "be ordered by position with prereleases" do
        get_show(@rubygem, 'xml')
        xml = Nokogiri.parse(@response.body).css('number')
        assert_equal "2.0.0", xml[0].content
        assert_equal "1.0.0.pre", xml[1].content
      end

      should "be ordered by position" do
        get_show(@rubygem2, 'xml')
        xml = Nokogiri.parse(@response.body).css('number')
        assert_equal "3.0.0", xml[0].content
        assert_equal "2.0.0", xml[1].content
        assert_equal "1.0.0", xml[2].content
      end

      should "have some XML with the list of versions for the second gem" do
        get_show(@rubygem2, 'xml')
        assert_equal 3, Nokogiri.parse(@response.body).css('version').size
      end
    end
  end

  context "on GET to show for an unknown gem" do
    setup do
      get :show, :id => "nonexistent_gem"
    end

    should "return a 404" do
      assert_response :not_found
    end

    should "say gem could not be found" do
      assert_equal "This rubygem could not be found.", @response.body
    end
  end

  context "on GET to show with lots of gems" do
    setup do
      @rubygem = Factory(:rubygem)
      12.times do |n|
        Factory(:version, :rubygem => @rubygem, :number => "#{n}.0.0")
      end
    end

    should "give all releases" do
      get_show(@rubygem)
      assert_equal 12, JSON.parse(@response.body).size
    end
  end
end
