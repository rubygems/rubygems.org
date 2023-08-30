require "test_helper"

class Api::V2::ContentsControllerTest < ActionController::TestCase
  def get_index(rubygem, version_number, platform = nil, format: :sha256)
    get :index, params: { rubygem_name: rubygem.name, version_number:, platform:, format: }.compact
  end

  def set_cache_header
    @request.if_modified_since = @response.headers["Last-Modified"]
    @request.if_none_match = @response.etag
  end

  context "routing to index" do
    should "route to index" do
      expected = { controller: "api/v2/contents", action: "index", rubygem_name: "foo", version_number: "1.0.0" }

      assert_recognizes expected, "/api/v2/rubygems/foo/versions/1.0.0/contents"
    end

    should "route to index with .json" do
      expected = { controller: "api/v2/contents", action: "index", rubygem_name: "foo", version_number: "1.0.0", format: "json" }

      assert_recognizes expected, "/api/v2/rubygems/foo/versions/1.0.0/contents.json"
    end

    should "route to index with .yaml" do
      expected = { controller: "api/v2/contents", action: "index", rubygem_name: "foo", version_number: "1.0.0", format: "yaml" }

      assert_recognizes expected, "/api/v2/rubygems/foo/versions/1.0.0/contents.yaml"
    end

    should "route to index with .sha256" do
      expected = { controller: "api/v2/contents", action: "index", rubygem_name: "foo", version_number: "1.0.0", format: "sha256" }

      assert_recognizes expected, "/api/v2/rubygems/foo/versions/1.0.0/contents.sha256"
    end

    should "not be confused by prerelease versions" do
      expected = { controller: "api/v2/contents", action: "index", rubygem_name: "foo", version_number: "1.0.0-a.pre" }

      assert_recognizes expected, "/api/v2/rubygems/foo/versions/1.0.0-a.pre/contents"
    end

    should "not route when disallowed characters are used" do
      assert_raises(ActionController::UrlGenerationError) do
        get :index, params: { rumgem_name: "foo", version_number: "bad%20version", format: "json" }
      end
    end
  end

  context "on GET to index" do
    setup do
      @rubygem = create(:rubygem)
      @jruby_version = create(:version, rubygem: @rubygem, number: "2.0.0", platform: "jruby")
      @version = create(:version, rubygem: @rubygem, number: "2.0.0")
      create(:version, rubygem: @rubygem, number: "1.0.0.pre", prerelease: true)
      create(:version, rubygem: @rubygem, number: "3.0.0", indexed: false)

      @rubygem2 = create(:rubygem)
      create(:version, rubygem: @rubygem2, number: "3.0.0")
      create(:version, rubygem: @rubygem2, number: "2.0.0")
      create(:version, rubygem: @rubygem2, number: "1.0.0")

      @checksums = { "file.rb" => "abc12345", "file2.rb" => "def67890" }
      @version.manifest.store_checksums(@checksums)

      @jruby_checksums = { "file.rb" => "c0ffee11", "file2.rb" => "c0ffee22" }
      @jruby_version.manifest.store_checksums(@jruby_checksums)
    end

    context "with .json format" do
      should "return checksums for the gem" do
        get_index(@rubygem, "2.0.0", format: :json)

        assert_response :success

        data = JSON.parse(@response.body)
        expected_data = @checksums.transform_values { |checksum| { "sha256" => checksum } }

        assert_equal expected_data, data
      end
    end

    context "with .yaml format" do
      should "return checksums for the gem" do
        get_index(@rubygem, "2.0.0", format: :yaml)

        assert_response :success

        data = YAML.safe_load(@response.body)
        expected_data = @checksums.transform_values { |checksum| { "sha256" => checksum } }

        assert_equal expected_data, data
      end
    end

    context "with .sha256 format" do
      should "return not found when the hashed files are not available" do
        get_index(@rubygem, "1.0.0.pre")

        assert_response :not_found
        assert_equal "Content is unavailable for this version.", @response.body
      end

      should "return not found when the gem is not indexed" do
        get_index(@rubygem, "3.0.0")

        assert_response :not_found
        assert_equal "This version could not be found.", @response.body
      end

      should "return a list of contents for the first gem" do
        get_index(@rubygem, "2.0.0")

        assert_response :success
        assert_equal <<~CHECKSUMS, @response.body
          abc12345  file.rb
          def67890  file2.rb
        CHECKSUMS
      end

      should "not be confused by ruby platform" do
        get :index, params: { rubygem_name: @rubygem.name, version_number: "2.0.0", platform: "ruby", format: :sha256 }

        assert_response :success
        assert_equal <<~CHECKSUMS, @response.body
          abc12345  file.rb
          def67890  file2.rb
        CHECKSUMS
      end

      should "return jruby version with platform param" do
        get_index @rubygem, "2.0.0", "jruby"

        assert_response :success
        assert_equal <<~CHECKSUMS, @response.body
          c0ffee11  file.rb
          c0ffee22  file2.rb
        CHECKSUMS
      end
    end

    should "return a platformed gem even without platform param if it was created more recently" do
      darwin_version = create(:version, rubygem: @rubygem, number: "2.0.0", platform: "universal-darwin-20")
      darwin_checksums = { "file.rb" => "file.rb-darwin", "file2.rb" => "file2.rb-darwin" }
      darwin_version.manifest.store_checksums(darwin_checksums)

      get_index @rubygem, "2.0.0", format: :json

      assert_response :success
      data = JSON.parse(@response.body)
      expected_data = darwin_checksums.transform_values { |checksum| { "sha256" => checksum } }

      assert_equal expected_data, data
    end

    should "return Last-Modified header" do
      get_index(@rubygem, "2.0.0")

      assert_equal @response.headers["Last-Modified"], @rubygem.updated_at.httpdate
    end

    should "return 304 when If-Modified-Since header is satisfied" do
      get_index(@rubygem, "2.0.0")

      assert_response :success
      set_cache_header

      get_index(@rubygem, "2.0.0")

      assert_response :not_modified
    end

    should "return 200 when If-Modified-Since header is not satisfied" do
      get_index(@rubygem, "2.0.0")

      assert_response :success
      set_cache_header

      @rubygem.update(updated_at: Time.zone.now + 1)
      get_index(@rubygem, "2.0.0")

      assert_response :success
    end

    should "return 404 if all versions yanked" do
      get_index(@rubygem, "2.0.0")

      assert_response :success
      set_cache_header

      travel_to(Time.zone.now + 1) do
        @rubygem.public_versions.each { |v| v.update!(indexed: false) }
      end

      get_index(@rubygem, "2.0.0")

      assert_response :not_found
    end
  end

  context "on GET to index for an unknown gem" do
    setup do
      get_index(Rubygem.new(name: "nonexistent_gem"), "1.2.3")
    end

    should "return a 404" do
      assert_response :not_found
    end

    should "say gem could not be found" do
      assert_equal "This gem could not be found", @response.body
    end
  end

  context "on GET to index for a yanked gem" do
    setup do
      @rubygem = create(:rubygem)
      create(:version, rubygem: @rubygem, indexed: false, number: "1.0.0")
      get_index(@rubygem, "2.0.0")
    end

    should "return a 404" do
      assert_response :not_found
    end

    should "say gem could not be found" do
      assert_equal "This version could not be found.", @response.body
    end

    should "should cache the 404" do
      set_cache_header

      get_index(@rubygem, "2.0.0")

      assert_response :not_modified
    end
  end
end
