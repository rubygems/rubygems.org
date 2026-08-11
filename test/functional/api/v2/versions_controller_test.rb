# frozen_string_literal: true

require "test_helper"

class Api::V2::VersionsControllerTest < ActionController::TestCase
  def get_show(rubygem, version, format = "json")
    get :show, params: { rubygem_name: rubygem.name, number: version, format: format }
  end

  def set_cache_header
    @request.if_modified_since = @response.headers["Last-Modified"]
    @request.if_none_match = @response.etag
  end

  def self.should_respond_to(format)
    context "with #{format.to_s.upcase}" do
      should "have a list of versions for the first gem" do
        get_show(@rubygem, "2.0.0", format)
        yield @response.body

        assert_response :success
      end
    end
  end

  context "routing to show" do
    should "route to show" do
      expected = { controller: "api/v2/versions", action: "show", rubygem_name: "foo", number: "1.0.0" }

      assert_recognizes expected, "/api/v2/rubygems/foo/versions/1.0.0"
    end

    should "route to show with .json" do
      expected = { controller: "api/v2/versions", action: "show", rubygem_name: "foo", number: "1.0.0", format: "json" }

      assert_recognizes expected, "/api/v2/rubygems/foo/versions/1.0.0.json"
    end

    should "route to show with .yaml" do
      expected = { controller: "api/v2/versions", action: "show", rubygem_name: "foo", number: "1.0.0", format: "yaml" }

      assert_recognizes expected, "/api/v2/rubygems/foo/versions/1.0.0.yaml"
    end

    should "not be confused by prerelease versions" do
      expected = { controller: "api/v2/versions", action: "show", rubygem_name: "foo", number: "1.0.0-a.pre" }

      assert_recognizes expected, "/api/v2/rubygems/foo/versions/1.0.0-a.pre"
    end

    should "not route when disallowed characters are used" do
      assert_raises(ActionController::UrlGenerationError) do
        get :show, params: { rumgem_name: "foo", number: "bad%20version", format: "json" }
      end
    end
  end

  context "on GET to show" do
    setup do
      @rubygem = create(:rubygem)
      create(:version, rubygem: @rubygem, number: "2.0.0")
      create(:version, rubygem: @rubygem, number: "1.0.0.pre", prerelease: true)
      create(:version, rubygem: @rubygem, number: "3.0.0", indexed: false)

      @rubygem2 = create(:rubygem)
      create(:version, rubygem: @rubygem2, number: "3.0.0")
      create(:version, rubygem: @rubygem2, number: "2.0.0")
      create(:version, rubygem: @rubygem2, number: "1.0.0")
    end

    context "with versions across Ruby ABIs" do
      setup do
        @rubygem = create(:rubygem, name: "sandworm")
        @abi32 = create(:version, rubygem: @rubygem, number: "1.0.0", platform: "x86_64-linux-musl", gem_platform: "x86_64-linux-musl",
                        required_ruby_version: "~> 3.2.0", ruby_abi: "3.2", sha256: Digest::SHA2.base64digest("sandworm-1.0.0-3.2"))
        @abi34 = create(:version, rubygem: @rubygem, number: "1.0.0", platform: "x86_64-linux-musl", gem_platform: "x86_64-linux-musl",
                        required_ruby_version: "~> 3.4.0", ruby_abi: "3.4", sha256: Digest::SHA2.base64digest("sandworm-1.0.0-3.4"))
        @multi = create(:version, rubygem: @rubygem, number: "1.0.0", platform: "x86_64-linux-musl", gem_platform: "x86_64-linux-musl",
                        required_ruby_version: ">= 3.2", sha256: Digest::SHA2.base64digest("sandworm-1.0.0-multi"),
                        spec_sha256: Digest::SHA2.base64digest("spec-multi"))
      end

      should "return the targeted Ruby ABI variant when ruby_abi is given" do
        get :show, params: { rubygem_name: @rubygem.name, number: "1.0.0", platform: "x86_64-linux-musl", ruby_abi: "3.2", format: "json" }

        assert_response :success
        payload = JSON.parse(@response.body)

        assert_equal "3.2", payload["ruby_abi"]
        assert_equal @abi32.sha256_hex, payload["sha"]
      end

      should "return the version supporting multiple Ruby ABIs without a ruby_abi param" do
        get :show, params: { rubygem_name: @rubygem.name, number: "1.0.0", platform: "x86_64-linux-musl", format: "json" }

        assert_response :success
        payload = JSON.parse(@response.body)

        assert_nil payload["ruby_abi"]
        assert_equal @multi.sha256_hex, payload["sha"]
      end

      should "return not found for a ruby_abi that does not match any variant" do
        get :show, params: { rubygem_name: @rubygem.name, number: "1.0.0", platform: "x86_64-linux-musl", ruby_abi: "3.3", format: "json" }

        assert_response :not_found
      end

      should "return bad request when ruby_abi is given without a platform" do
        get :show, params: { rubygem_name: @rubygem.name, number: "1.0.0", ruby_abi: "3.2", format: "json" }

        assert_response :bad_request
        assert_equal "The platform param is required when ruby_abi is specified.", @response.body
      end

      should "return bad request when ruby_abi has an invalid format" do
        get :show, params: { rubygem_name: @rubygem.name, number: "1.0.0", platform: "x86_64-linux-musl", ruby_abi: "invalid", format: "json" }

        assert_response :bad_request
        assert_equal "The ruby_abi param must be in the format X.Y (e.g., 3.2).", @response.body
      end

      should "treat empty ruby_abi as absent" do
        get :show, params: { rubygem_name: @rubygem.name, number: "1.0.0", platform: "x86_64-linux-musl", ruby_abi: "", format: "json" }

        assert_response :success
        payload = JSON.parse(@response.body)

        assert_nil payload["ruby_abi"]
        assert_equal @multi.sha256_hex, payload["sha"]
      end

      should "reject boundary near-misses for ruby_abi format" do
        %w[3 3.2.1 3.].each do |invalid|
          get :show, params: { rubygem_name: @rubygem.name, number: "1.0.0", platform: "x86_64-linux-musl", ruby_abi: invalid, format: "json" }

          assert_response :bad_request
          assert_equal "The ruby_abi param must be in the format X.Y (e.g., 3.2).", @response.body
        end
      end

      should "return format error when ruby_abi is invalid and platform is missing" do
        get :show, params: { rubygem_name: @rubygem.name, number: "1.0.0", ruby_abi: "invalid", format: "json" }

        assert_response :bad_request
        assert_equal "The ruby_abi param must be in the format X.Y (e.g., 3.2).", @response.body
      end

      should "return bad request for invalid ruby_abi even when version does not exist" do
        get :show, params: { rubygem_name: @rubygem.name, number: "999.0.0", platform: "x86_64-linux-musl", ruby_abi: "invalid", format: "json" }

        assert_response :bad_request
        assert_equal "The ruby_abi param must be in the format X.Y (e.g., 3.2).", @response.body
      end
    end

    should_respond_to(:json) do |body|
      JSON.parse(body)
    end

    should_respond_to(:yaml) do |body|
      YAML.safe_load(body)
    end

    should "return Last-Modified header" do
      get_show(@rubygem, "2.0.0")

      assert_equal @response.headers["Last-Modified"], @rubygem.updated_at.httpdate
    end

    should "return 304 when If-Modified-Since header is satisfied" do
      get_show(@rubygem, "2.0.0")

      assert_response :success
      set_cache_header

      get_show(@rubygem, "2.0.0")

      assert_response :not_modified
    end

    should "return 200 when If-Modified-Since header is not satisfied" do
      get_show(@rubygem, "2.0.0")

      assert_response :success
      set_cache_header

      @rubygem.update(updated_at: Time.zone.now + 1)
      get_show(@rubygem, "2.0.0")

      assert_response :success
    end

    should "return 404 if all versions yanked" do
      get_show(@rubygem, "2.0.0")

      assert_response :success
      set_cache_header

      travel_to(Time.zone.now + 1) do
        @rubygem.public_versions.each { |v| v.update!(indexed: false) }
      end

      get_show(@rubygem, "2.0.0")

      assert_response :not_found
    end

    context "same version with mulitple platform" do
      setup do
        create(:version, rubygem: @rubygem, number: "2.0.0", platform: "jruby")
      end

      should "return version by position without platform param" do
        get_show(@rubygem, "2.0.0")

        assert_response :success
        response = JSON.load(@response.body)

        assert_equal "jruby", response["platform"]
        assert_equal "2.0.0", response["version"]
      end

      should "return platform version with platform param" do
        get :show, params: { rubygem_name: @rubygem.name, number: "2.0.0", platform: "ruby", format: "json" }

        assert_response :success
        response = JSON.load(@response.body)

        assert_equal "ruby", response["platform"]
        assert_equal "2.0.0", response["version"]
      end
    end
  end

  context "on GET to show for an unknown gem" do
    setup do
      get_show(Rubygem.new(name: "nonexistent_gem"), "1.2.3")
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
      create(:version, rubygem: @rubygem, indexed: false, number: "1.0.0")
      get_show(@rubygem, "2.0.0")
    end

    should "return a 404" do
      assert_response :not_found
    end

    should "say gem could not be found" do
      assert_equal "This version could not be found.", @response.body
    end

    should "should cache the 404" do
      set_cache_header

      get_show(@rubygem, "2.0.0")

      assert_response :not_modified
    end
  end

  context "on GET to show a gem with lots of versions" do
    setup do
      @rubygem = create(:rubygem)
      12.times do |n|
        create(:version, rubygem: @rubygem, number: "#{n}.0.0")
      end
    end

    should "gives one specific version" do
      get_show(@rubygem, "4.0.0")

      assert_kind_of Hash, JSON.load(@response.body)
      assert_equal "4.0.0", JSON.load(@response.body)["number"]
    end
  end

  context "on GET to show for a gem with a license" do
    setup do
      @rubygem = create(:rubygem)
      create(:version, rubygem: @rubygem, number: "2.0.0")
      get_show(@rubygem, "2.0.0")
      @response = JSON.load(@response.body)
    end

    should("have sha") { assert @response["sha"] }
    should("have platform") { assert @response["platform"] }
    should("have ruby_version") { assert @response["ruby_version"] }
    should("have dependencies") { assert @response["dependencies"] }
    should("have development dependencies") { assert @response["dependencies"]["development"] }
    should("have runtime dependencies") { assert @response["dependencies"]["runtime"] }
    should "have expected keys" do
      assert_equal(
        %w[
          name downloads version version_created_at version_downloads platform
          ruby_abi authors info licenses metadata yanked sha spec_sha project_uri gem_uri
          homepage_uri wiki_uri documentation_uri mailing_list_uri
          source_code_uri bug_tracker_uri changelog_uri funding_uri dependencies
          built_at created_at description downloads_count number summary
          rubygems_version ruby_version prerelease requirements
        ],
        @response.keys
      )
    end
  end
end
