require "test_helper"

class Api::V1::VersionsControllerTest < ActionController::TestCase
  def get_show(rubygem, format = "json")
    get :show, params: { id: rubygem.name, format: format }
  end

  def get_latest(rubygem, format = "json")
    get :latest, params: { id: rubygem.name, format: format }
  end

  def get_reverse_dependencies(rubygem, format: "json")
    get :reverse_dependencies, params: { id: rubygem.name, format: format }
  end

  def set_cache_header
    @request.if_modified_since = @response.headers["Last-Modified"]
    @request.if_none_match = @response.etag
  end

  def self.should_respond_to(format)
    context "with #{format.to_s.upcase}" do
      should "have a list of versions for the first gem" do
        get_show(@rubygem, format)
        assert_equal 3, yield(@response.body).size
      end

      should "be ordered by position with prereleases" do
        get_show(@rubygem, format)
        arr = yield(@response.body)
        assert_equal "4.0.0", arr.first["number"]
        assert_equal "2.0.0", arr.second["number"]
        assert_equal "1.0.0.pre", arr.third["number"]
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
      create(:version, rubygem: @rubygem, number: "2.0.0")
      create(:version, rubygem: @rubygem, number: "1.0.0.pre", prerelease: true)
      create(:version, rubygem: @rubygem, number: "3.0.0", indexed: false)
      create(:version, rubygem: @rubygem, number: "4.0.0", built_at: 2.days.from_now)

      @rubygem2 = create(:rubygem)
      create(:version, rubygem: @rubygem2, number: "3.0.0")
      create(:version, rubygem: @rubygem2, number: "2.0.0")
      create(:version, rubygem: @rubygem2, number: "1.0.0")
    end

    should_respond_to(:json) do |body|
      JSON.load(body)
    end

    should_respond_to(:yaml) do |body|
      YAML.safe_load(body)
    end

    should "return Last-Modified header" do
      get_show(@rubygem)
      assert_equal @response.headers["Last-Modified"], @rubygem.updated_at.httpdate
    end

    should "return surrogate key header" do
      get_show(@rubygem)
      assert_equal "gem/#{@rubygem.name}", @response.headers["Surrogate-Key"]
    end

    should "return 304 when If-Modified-Since header is satisfied" do
      get_show(@rubygem)
      assert_response :success
      set_cache_header

      get_show(@rubygem)
      assert_response :not_modified
    end

    should "return 200 when If-Modified-Since header is not satisfied" do
      get_show(@rubygem)
      assert_response :success
      set_cache_header

      @rubygem.update(updated_at: Time.zone.now + 1)
      get_show(@rubygem)
      assert_response :success
    end

    should "return 404 if all versions yanked" do
      get_show(@rubygem)
      assert_response :success
      set_cache_header

      travel 1.second do
        @rubygem.public_versions.each { |v| v.update!(indexed: false) }
      end

      get_show(@rubygem)
      assert_response :not_found
    end
  end

  context "on GET to show for an unknown gem" do
    setup do
      get :show, params: { id: "nonexistent_gem", format: "json" }
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
      create(:version, rubygem: @rubygem, indexed: false, number: "1.0.0")
      get_show(@rubygem)
    end

    should "return a 404" do
      assert_response :not_found
    end

    should "say gem could not be found" do
      assert_equal "This rubygem could not be found.", @response.body
    end

    should "should cache the 404" do
      set_cache_header

      get_show(@rubygem)
      assert_response :not_modified
    end
  end

  context "on GET to show with lots of gems" do
    setup do
      @rubygem = create(:rubygem)
      12.times do |n|
        create(:version, rubygem: @rubygem, number: "#{n}.0.0")
      end
    end

    should "give all releases" do
      get_show(@rubygem)
      assert_equal 12, JSON.load(@response.body).size
    end
  end

  context "on GET to latest" do
    setup do
      @rubygem = create(:rubygem)
      (1..3).each do |n|
        create(:version, rubygem: @rubygem, number: "#{n}.0.0")
      end
    end

    should "return latest version" do
      get_latest @rubygem
      assert_equal "3.0.0", JSON.load(@response.body)["version"]
    end
  end

  context "on GET to jsonp version of latest" do
    setup do
      @rubygem = create(:rubygem)
      (1..3).each do |n|
        create(:version, rubygem: @rubygem, number: "#{n}.0.0")
      end
    end

    should "return latest version" do
      get :latest, params: { id: @rubygem.name, format: "js", callback: "blah" }
      assert_match(/blah\(.*\)\Z/, @response.body)
    end
  end

  context "on GET to of latest for unknown gem" do
    setup do
      @rubygem = create(:rubygem)
      (1..3).each do |n|
        create(:version, rubygem: @rubygem, number: "#{n}.0.0")
      end
    end

    should "return latest version" do
      get :latest, params: { id: "blah", format: "json" }
      assert_equal "unknown", JSON.load(@response.body)["version"]
    end
  end

  context "on GET to of latest for a gem with no versions" do
    setup do
      @rubygem = create(:rubygem)
      @version = create(:version, rubygem: @rubygem, number: "1.0.0", indexed: false)
    end

    should "return latest version" do
      get :latest, params: { id: @rubygem.name, format: "json" }
      assert_equal "unknown", JSON.load(@response.body)["version"]
    end
  end

  context "on GET to of latest for a gem with different platform versions" do
    setup do
      @rubygem = create(:rubygem)
      @version_one = create(:version, rubygem: @rubygem, number: "1.0.0", platform: "x86-linux")
      @version_two = create(:version, rubygem: @rubygem, number: "2.0.0", platform: "ruby")
    end

    should "return most recent version" do
      get :latest, params: { id: @rubygem.name, format: "json" }
      assert_equal "2.0.0", JSON.load(@response.body)["version"]
    end
  end

  context "on GET to show for a gem with a license" do
    setup do
      @rubygem = create(:rubygem)
      create(:version, rubygem: @rubygem, licenses: "MIT")
    end

    should "return license info" do
      get :show, params: { id: @rubygem.name, format: "json" }
      assert_equal "MIT", JSON.load(@response.body).first["licenses"]
    end
  end

  context "on GET to reverse_dependencies" do
    setup do
      @dep_rubygem = create(:rubygem)
      @gem_one = create(:rubygem)
      @gem_two = create(:rubygem)
      @gem_three = create(:rubygem)
      @version_one_latest = create(:version,
        rubygem: @gem_one,
        number: "0.2",
        full_name: "gem_one-0.2")
      @version_one_earlier = create(:version,
        rubygem: @gem_one,
        number: "0.1",
        full_name: "gem_one-0.1")
      @version_two_latest = create(:version,
        rubygem: @gem_two,
        number: "1.0",
        full_name: "gem_two-1.0")
      @version_two_earlier = create(:version,
        rubygem: @gem_two,
        number: "0.5",
        full_name: "gem_two-0.5")
      @version_three = create(:version,
        rubygem: @gem_three,
        number: "1.7",
        full_name: "gem_three-1.7")

      @version_one_latest.dependencies << create(:dependency,
        version: @version_one_latest,
        rubygem: @dep_rubygem)
      @version_two_earlier.dependencies << create(:dependency,
        version: @version_two_earlier,
        rubygem: @dep_rubygem)
      @version_three.dependencies << create(:dependency,
        version: @version_three,
        rubygem: @dep_rubygem)
    end

    should "return names of reverse dependencies" do
      get_reverse_dependencies(@dep_rubygem, format: "json")
      ret_versions = JSON.load(@response.body)

      assert_equal 3, ret_versions.size

      assert_includes ret_versions, @version_one_latest.full_name
      assert_includes ret_versions, @version_two_earlier.full_name
      assert_includes ret_versions, @version_three.full_name
      refute_includes ret_versions, @version_one_earlier.full_name
      refute_includes ret_versions, @version_two_latest.full_name
    end
  end
end
