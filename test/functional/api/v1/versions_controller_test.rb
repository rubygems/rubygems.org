require 'test_helper'

class Api::V1::VersionsControllerTest < ActionController::TestCase
  def get_show(rubygem, format='json')
    get :show, :id => rubygem.name, :format => format
  end

  def self.should_respond_to(format)
    context "with #{format.to_s.upcase}" do
      should "have a list of versions for the first gem" do
        get_show(@rubygem, format)
        assert_equal 2, yield(@response.body).size
      end

      should "be ordered by position with prereleases" do
        get_show(@rubygem, format)
        arr = yield(@response.body)
        assert_equal "2.0.0", arr.first["number"]
        assert_equal "1.0.0.pre", arr.second["number"]
      end

      should "be ordered by position" do
        get_show(@rubygem2, format)
        arr = yield(@response.body)
        assert_equal "3.0.0", arr.first["number"]
        assert_equal "2.0.0", arr.second["number"]
        assert_equal "1.0.0", arr.third["number"]
      end

      should "have a list of versions for the second gem" do
        get_show(@rubygem2, format)
        assert_equal 3, yield(@response.body).size
      end
    end
  end

  context "on GET to show" do
    setup do
      @rubygem = create(:rubygem)
      create(:version, :rubygem => @rubygem, :number => '2.0.0')
      create(:version, :rubygem => @rubygem, :number => '1.0.0.pre', :prerelease => true)
      create(:version, :rubygem => @rubygem, :number => '3.0.0', :indexed => false)

      @rubygem2 = create(:rubygem)
      create(:version, :rubygem => @rubygem2, :number => '3.0.0')
      create(:version, :rubygem => @rubygem2, :number => '2.0.0')
      create(:version, :rubygem => @rubygem2, :number => '1.0.0')
    end

    should_respond_to(:json) do |body|
      MultiJson.load(body)
    end

    should_respond_to(:xml) do |body|
      Hash.from_xml(Nokogiri.parse(body).to_xml)['versions']
    end

    should_respond_to(:yaml) do |body|
      YAML.load(body)
    end

    should "return Last-Modified header" do
      get_show(@rubygem)
      assert_equal @response.headers['Last-Modified'], @rubygem.updated_at.httpdate
    end

    should "return 304 when If-Modified-Since header is satisfied" do
      set_cache_header(@rubygem.updated_at)
      get_show(@rubygem)
      assert_response :not_modified
    end

    should "return 200 when If-Modified-Since header is not satisfied" do
      set_cache_header(@rubygem.updated_at - 1)
      get_show(@rubygem)
      assert_response :success
    end

    def set_cache_header(timestamp)
      ims = ActionDispatch::Http::Cache::Request::HTTP_IF_MODIFIED_SINCE
      request.env[ims] = timestamp.httpdate
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

  context "on GET to show for a yanked gem" do
    setup do
      @rubygem = create(:rubygem)
      create(:version, :rubygem => @rubygem, :indexed => false, :number => '1.0.0')
      get_show(@rubygem)
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
      @rubygem = create(:rubygem)
      12.times do |n|
        create(:version, :rubygem => @rubygem, :number => "#{n}.0.0")
      end
    end

    should "give all releases" do
      get_show(@rubygem)
      assert_equal 12, MultiJson.load(@response.body).size
    end
  end

end
