require 'test_helper'

class Api::V2::VersionsControllerTest < ActionController::TestCase
  def get_show(rubygem, version, format = 'json')
    get :show, params: { rubygem_name: rubygem.name, number: version, format: format }
  end

  def set_cache_header
    @request.if_modified_since = @response.headers['Last-Modified']
    @request.if_none_match = @response.etag
  end

  def self.should_respond_to(format)
    context "with #{format.to_s.upcase}" do
      should "have a list of versions for the first gem" do
        get_show(@rubygem, '2.0.0', format)
        @response.body
        assert_response :success
      end
    end
  end

  context "on GET to show" do
    setup do
      @rubygem = create(:rubygem)
      create(:version, rubygem: @rubygem, number: '2.0.0')
      create(:version, rubygem: @rubygem, number: '1.0.0.pre', prerelease: true)
      create(:version, rubygem: @rubygem, number: '3.0.0', indexed: false)

      @rubygem2 = create(:rubygem)
      create(:version, rubygem: @rubygem2, number: '3.0.0')
      create(:version, rubygem: @rubygem2, number: '2.0.0')
      create(:version, rubygem: @rubygem2, number: '1.0.0')
    end

    should_respond_to(:json) do |body|
      JSON.load(body)
    end

    should_respond_to(:yaml) do |body|
      YAML.load(body)
    end

    should "return Last-Modified header" do
      get_show(@rubygem, '2.0.0')
      assert_equal @response.headers['Last-Modified'], @rubygem.updated_at.httpdate
    end

    should "return 304 when If-Modified-Since header is satisfied" do
      get_show(@rubygem, '2.0.0')
      assert_response :success
      set_cache_header

      get_show(@rubygem, '2.0.0')
      assert_response :not_modified
    end

    should "return 200 when If-Modified-Since header is not satisfied" do
      get_show(@rubygem, '2.0.0')
      assert_response :success
      set_cache_header

      @rubygem.update(updated_at: Time.zone.now + 1)
      get_show(@rubygem, '2.0.0')
      assert_response :success
    end

    should "return 404 if all versions yanked" do
      get_show(@rubygem, '2.0.0')
      assert_response :success
      set_cache_header

      travel_to(Time.zone.now + 1) do
        @rubygem.public_versions.each { |v| v.update!(indexed: false) }
      end

      get_show(@rubygem, '2.0.0')
      assert_response :not_found
    end
  end

  context "on GET to show for an unknown gem" do
    setup do
      get_show(Rubygem.new(name: "nonexistent_gem"), '1.2.3')
    end

    should "return a 404" do
      assert_response :not_found
    end

    should "say gem could not be found" do
      assert_equal "This gem could not be found", @response.body
    end
  end

  context "on GET to show for a yanked gem" do
    setup do
      @rubygem = create(:rubygem)
      create(:version, rubygem: @rubygem, indexed: false, number: '1.0.0')
      get_show(@rubygem, '2.0.0')
    end

    should "return a 404" do
      assert_response :not_found
    end

    should "say gem could not be found" do
      assert_equal "This version could not be found.", @response.body
    end

    should "should cache the 404" do
      set_cache_header

      get_show(@rubygem, '2.0.0')
      assert_response :not_modified
    end
  end

  context "on GET to show a gem with with lots of versions" do
    setup do
      @rubygem = create(:rubygem)
      12.times do |n|
        create(:version, rubygem: @rubygem, number: "#{n}.0.0")
      end
    end

    should "gives one specific version" do
      get_show(@rubygem, '4.0.0')
      assert_kind_of Hash, JSON.load(@response.body)
      assert_equal "4.0.0", JSON.load(@response.body)["number"]
    end

    context "expected attributes by compact index" do
      setup do
      end
    end
  end

  context "on GET to show for a gem with a license" do
    setup do
      @rubygem = create(:rubygem)
      create(:version, rubygem: @rubygem, number: "2.0.0")
      get_show(@rubygem, '2.0.0')
      @response = JSON.load(@response.body)
    end

    should("have sha") { assert @response["sha"] }
    should("have platform") { assert @response["platform"] }
    should("have ruby_version") { assert @response["ruby_version"] }
  end
end
