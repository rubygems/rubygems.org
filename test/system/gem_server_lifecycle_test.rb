# frozen_string_literal: true

require "application_system_test_case"

require_relative "../../lib/gemcutter/middleware/hostess"

class GemServerLifecycleTest < ApplicationSystemTestCase
  include ActionDispatch::Assertions::RoutingAssertions
  include ActiveJob::TestHelper
  include RakeTaskHelper

  setup do
    @tmp_versions_file = Tempfile.new("tmp_versions_file")
    tmp_path = @tmp_versions_file.path

    Rails.application.config.rubygems.stubs(:[]).with("versions_file_location").returns(tmp_path)
    Rails.application.config.rubygems.stubs(:[]).with("s3_compact_index_bucket").returns("s3_compact_index_bucket")
    Rails.application.config.rubygems.stubs(:[]).with("s3_contents_bucket").returns("s3_contents_bucket")

    setup_rake_tasks("compact_index.rake")

    Rails.application.routes.disable_clear_and_finalize = true
    Rails.application.routes.draw do
      post "/rebuild_versions_list", to: lambda { |_env|
        Rake::Task["compact_index:update_versions_file"].execute
        [200, {}, ["OK"]]
      }
      hostess = Gemcutter::Middleware::Hostess.new(nil)
      to = lambda { |env|
        hostess.call(env)
          .tap do |response|
          response[1].delete("x-cascade")
        end
      }
      match "/quick/Marshal.4.8/:name", to:, via: :get, constraints: { name: /[A-Za-z0-9._-]+/ }
      match "/gems/:name", to:, via: :get, constraints: { name: Patterns::ROUTE_PATTERN }
      match "/specs.4.8.gz", to:, via: :get
      match "/prerelease_specs.4.8.gz", to:, via: :get
      match "/latest_specs.4.8.gz", to:, via: :get
    end

    Indexer.perform_now
    @subscriber = ActiveSupport::Notifications.subscribe("process_action.action_controller") do
      perform_enqueued_jobs only: [Indexer]
    end

    @time = Time.utc(1990)
    travel_to @time
    @all_gems = []
    @api_key = "12345"
    create(:api_key, scopes: %w[push_rubygem yank_rubygem], key: @api_key)
  end

  teardown do
    ActiveSupport::Notifications.unsubscribe(@subscriber)
    Rails.application.reload_routes!
  end

  test "gem server push, yank, and index lifecycle" do # rubocop:disable Minitest/MultipleAssertions
    # Step 1: after rebuilding empty versions list
    do_rebuild_versions_list

    response = do_get_versions
    assert_valid_compact_index_response response
    assert_equal "created_at: 1990-01-01T00:00:00Z\n---\n", response.body

    response = do_get_names
    assert_valid_compact_index_response response
    assert_equal "---\n\n", response.body

    response = do_get_specs
    assert_equal "200", response.code
    assert_equal [], unmarshal_gzipped(response.body)

    response = do_get_specs(:prerelease)
    assert_equal "200", response.code
    assert_equal [], unmarshal_gzipped(response.body)

    response = do_get_specs(:latest)
    assert_equal "200", response.code
    assert_equal [], unmarshal_gzipped(response.body)

    assert_equal "404", do_get_info("missing").code
    assert_equal "404", do_get_gem("missing").code
    assert_equal "404", do_get_quick_spec("missing").code

    # Step 2: push a-1.0.0
    gem_a_1_0_0 = build_test_gem("a", "1.0.0")
    do_push_gem(gem_a_1_0_0, expected_code: "200")

    assert_pushed_gem("a-1.0.0")

    versions_after_first_push = do_get_versions
    assert_valid_compact_index_response versions_after_first_push
    versions_body = versions_after_first_push.body
    assert_match(/\Acreated_at: .+\n---\na 1\.0\.0 \h{32}\n\z/, versions_body)

    info_a_after_first_push = do_get_info("a")
    assert_equal "200", info_a_after_first_push.code
    assert_equal "text/plain; charset=utf-8", info_a_after_first_push["content-type"]
    expected_info = "---\n1.0.0 |checksum:#{gem_a_1_0_0.sha256}\n"
    assert_equal expected_info, info_a_after_first_push.body

    response = do_get_names
    assert_valid_compact_index_response response
    assert_equal "---\na\n", response.body

    response = do_get_specs
    assert_equal "200", response.code
    assert_equal [["a", Gem::Version.new("1.0.0"), "ruby"]], unmarshal_gzipped(response.body)

    response = do_get_specs(:prerelease)
    assert_equal "200", response.code
    assert_equal [], unmarshal_gzipped(response.body)

    response = do_get_specs(:latest)
    assert_equal "200", response.code
    assert_equal [["a", Gem::Version.new("1.0.0"), "ruby"]], unmarshal_gzipped(response.body)

    assert_versions_etags_match_info(versions_after_first_push)

    # Step 3: yank a-1.0.0
    do_yank_gem(gem_a_1_0_0, expected_code: "200")

    assert_yanked_gem("a-1.0.0")

    versions_after_yank = do_get_versions
    assert_valid_compact_index_response versions_after_yank
    assert versions_after_yank.body.start_with?(versions_body), "versions should be appended"
    assert_match(/a -1\.0\.0 \h{32}\n\z/, versions_after_yank.body)

    info_a_after_yank = do_get_info("a")
    assert_valid_compact_index_response info_a_after_yank
    assert_equal "---\n", info_a_after_yank.body

    response = do_get_names
    assert_valid_compact_index_response response
    assert_equal "---\n\n", response.body

    response = do_get_specs
    assert_equal "200", response.code
    assert_equal [], unmarshal_gzipped(response.body)

    response = do_get_specs(:prerelease)
    assert_equal "200", response.code
    assert_equal [], unmarshal_gzipped(response.body)

    response = do_get_specs(:latest)
    assert_equal "200", response.code
    assert_equal [], unmarshal_gzipped(response.body)

    assert_versions_etags_match_info(versions_after_yank)

    # Step 4: push a-0.0.1 and b-1.0.0.pre
    gem_a_0_0_1 = build_test_gem("a", "0.0.1")
    do_push_gem(gem_a_0_0_1, expected_code: "200")

    gem_b_1_0_0_pre = build_test_gem("b", "1.0.0.pre") do |spec|
      spec.add_runtime_dependency "a", "< 1.0.0", ">= 0.1.0"
      spec.required_ruby_version = ">= 2.0"
      spec.required_rubygems_version = ">= 2.0"
    end
    do_push_gem(gem_b_1_0_0_pre, expected_code: "200")

    assert_pushed_gem("a-0.0.1")
    assert_pushed_gem("b-1.0.0.pre")

    versions_after_second_push = do_get_versions
    assert_valid_compact_index_response versions_after_second_push
    assert versions_after_second_push.body.start_with?(versions_after_yank.body), "versions should be appended"
    assert_match(/a 0\.0\.1 \h{32}\nb 1\.0\.0\.pre \h{32}\n\z/, versions_after_second_push.body)

    info_a_after_second_push = do_get_info("a")
    assert_valid_compact_index_response info_a_after_second_push
    assert_equal info_a_after_yank.body + "0.0.1 |checksum:#{gem_a_0_0_1.sha256}\n", info_a_after_second_push.body

    info_b = do_get_info("b")
    assert_valid_compact_index_response info_b
    assert_equal "---\n1.0.0.pre a:< 1.0.0&>= 0.1.0|checksum:#{gem_b_1_0_0_pre.sha256},ruby:>= 2.0,rubygems:>= 2.0\n", info_b.body

    response = do_get_names
    assert_valid_compact_index_response response
    assert_equal "---\na\nb\n", response.body

    response = do_get_specs
    assert_equal "200", response.code
    assert_equal [["a", Gem::Version.new("0.0.1"), "ruby"]], unmarshal_gzipped(response.body)

    response = do_get_specs(:prerelease)
    assert_equal "200", response.code
    assert_equal [["b", Gem::Version.new("1.0.0.pre"), "ruby"]], unmarshal_gzipped(response.body)

    response = do_get_specs(:latest)
    assert_equal "200", response.code
    assert_equal [["a", Gem::Version.new("0.0.1"), "ruby"]], unmarshal_gzipped(response.body)

    assert_versions_etags_match_info(versions_after_second_push)

    # Step 5: push duplicates and platform variants
    gem_a_0_0_1_dup = build_test_gem("a", "0.0.1") { |s| s.add_runtime_dependency "b", ">= 1.0.0" }
    do_push_gem(gem_a_0_0_1_dup, expected_code: "409")
    @all_gems.pop

    gem_a_0_2_0 = build_test_gem("a", "0.2.0")
    do_push_gem(gem_a_0_2_0, expected_code: "200")

    build_test_gem("a", "0.2.0", platform: "x86-mingw32")
    do_push_gem(@all_gems.last, expected_code: "200")

    build_test_gem("a", "0.2.0", platform: "java")
    do_push_gem(@all_gems.last, expected_code: "200")

    assert_pushed_gem("a-0.2.0")
    assert_pushed_gem("a-0.2.0-x86-mingw32")
    assert_pushed_gem("a-0.2.0-java")

    versions_after_third_push = do_get_versions
    assert_valid_compact_index_response versions_after_third_push
    assert versions_after_third_push.body.start_with?(versions_after_second_push.body), "versions should be appended"
    assert_match(/a 0\.2\.0 \h{32}\na 0\.2\.0-x86-mingw32 \h{32}\na 0\.2\.0-java \h{32}\n\z/,
      versions_after_third_push.body)

    info_a_after_third_push = do_get_info("a")
    assert_valid_compact_index_response info_a_after_third_push
    expected_info_a = info_a_after_second_push.body +
      "0.2.0 |checksum:#{gem_a_0_2_0.sha256}\n" \
      "0.2.0-x86-mingw32 |checksum:#{find_gem('a-0.2.0-x86-mingw32').sha256}\n" \
      "0.2.0-java |checksum:#{find_gem('a-0.2.0-java').sha256}\n"
    assert_equal expected_info_a, info_a_after_third_push.body

    specs_after_third_push = do_get_specs
    assert_equal "200", specs_after_third_push.code
    specs = unmarshal_gzipped(specs_after_third_push.body)
    assert_includes specs, ["a", Gem::Version.new("0.0.1"), "ruby"]
    assert_includes specs, ["a", Gem::Version.new("0.2.0"), "ruby"]
    assert_includes specs, ["a", Gem::Version.new("0.2.0"), "x86-mingw32"]
    assert_includes specs, ["a", Gem::Version.new("0.2.0"), "java"]

    response = do_get_specs(:latest)
    assert_equal "200", response.code
    latest = unmarshal_gzipped(response.body)
    assert_includes latest, ["a", Gem::Version.new("0.2.0"), "ruby"]
    assert_includes latest, ["a", Gem::Version.new("0.2.0"), "x86-mingw32"]
    assert_includes latest, ["a", Gem::Version.new("0.2.0"), "java"]

    response = do_get_specs(:prerelease)
    assert_equal "200", response.code
    assert_equal [["b", Gem::Version.new("1.0.0.pre"), "ruby"]], unmarshal_gzipped(response.body)

    assert_versions_etags_match_info(versions_after_third_push)

    # Step 6: rebuild versions list
    do_rebuild_versions_list

    versions_after_rebuild = do_get_versions
    assert_valid_compact_index_response versions_after_rebuild
    # After rebuild, versions file is compacted (no incremental lines)
    assert_match(/\Acreated_at: .+\n---\n/, versions_after_rebuild.body)
    assert_match(/^a .+ \h{32}$/, versions_after_rebuild.body)
    assert_match(/^b .+ \h{32}$/, versions_after_rebuild.body)

    # Step 7: push a-0.3.0
    gem_a_0_3_0 = build_test_gem("a", "0.3.0")
    do_push_gem(gem_a_0_3_0, expected_code: "200")

    assert_pushed_gem("a-0.3.0")

    versions_after_fourth_push = do_get_versions
    assert_valid_compact_index_response versions_after_fourth_push
    assert versions_after_fourth_push.body.start_with?(versions_after_rebuild.body), "versions should be appended"
    assert_match(/a 0\.3\.0 \h{32}\n\z/, versions_after_fourth_push.body)

    info_a_after_fourth_push = do_get_info("a")
    assert_valid_compact_index_response info_a_after_fourth_push
    assert_match(/0\.3\.0 \|checksum:#{gem_a_0_3_0.sha256}\n\z/, info_a_after_fourth_push.body)

    specs_after_fourth_push = do_get_specs
    assert_equal "200", specs_after_fourth_push.code
    specs = unmarshal_gzipped(specs_after_fourth_push.body)
    assert_includes specs, ["a", Gem::Version.new("0.3.0"), "ruby"]

    response = do_get_specs(:latest)
    assert_equal "200", response.code
    latest = unmarshal_gzipped(response.body)
    assert_includes latest, ["a", Gem::Version.new("0.3.0"), "ruby"]
    assert_includes latest, ["a", Gem::Version.new("0.2.0"), "x86-mingw32"]
    assert_includes latest, ["a", Gem::Version.new("0.2.0"), "java"]

    assert_versions_etags_match_info(versions_after_fourth_push)

    # Step 8: yank a-0.2.0
    do_yank_gem(gem_a_0_2_0, expected_code: "200")

    assert_yanked_gem("a-0.2.0")

    versions_after_second_yank = do_get_versions
    assert_valid_compact_index_response versions_after_second_yank
    assert versions_after_second_yank.body.start_with?(versions_after_fourth_push.body), "versions should be appended"
    assert_match(/a -0\.2\.0 \h{32}\n\z/, versions_after_second_yank.body)

    info_a_after_second_yank = do_get_info("a")
    assert_valid_compact_index_response info_a_after_second_yank
    # The yanked version line should be removed from info
    refute_match(/^0\.2\.0 \|checksum:#{gem_a_0_2_0.sha256}$/, info_a_after_second_yank.body)
    # Other versions should still be present
    assert_match(/0\.0\.1 \|checksum:/, info_a_after_second_yank.body)
    assert_match(/0\.3\.0 \|checksum:/, info_a_after_second_yank.body)

    specs_after_second_yank = do_get_specs
    assert_equal "200", specs_after_second_yank.code
    specs = unmarshal_gzipped(specs_after_second_yank.body)
    refute_includes specs, ["a", Gem::Version.new("0.2.0"), "ruby"]
    assert_includes specs, ["a", Gem::Version.new("0.3.0"), "ruby"]

    assert_versions_etags_match_info(versions_after_second_yank)

    # Step 9: rebuild versions list again
    do_rebuild_versions_list

    versions_after_final_rebuild = do_get_versions
    assert_valid_compact_index_response versions_after_final_rebuild
    assert_match(/\Acreated_at: .+\n---\n/, versions_after_final_rebuild.body)
    assert_match(/^a .+ \h{32}$/, versions_after_final_rebuild.body)
    assert_match(/^b .+ \h{32}$/, versions_after_final_rebuild.body)

    # Step 10: yank missing gem
    missing_gem = MockGem.new(name: "missing", version: Gem::Version.new("1.0.0"), platform: "ruby")
    do_yank_gem(missing_gem, expected_code: "404")
  end

  private

  def server_url
    "http://#{Capybara.current_session.config.server_host}:#{Capybara.current_session.config.server_port}"
  end

  def http_get(path)
    uri = URI("#{server_url}/#{path}")
    Net::HTTP.start(uri.host, uri.port) { |http| http.get(uri.request_uri) }
  end

  def http_post(path, body: nil, headers: {})
    uri = URI("#{server_url}/#{path}")
    Net::HTTP.start(uri.host, uri.port) do |http|
      req = Net::HTTP::Post.new(uri.request_uri)
      headers.each { |k, v| req[k] = v }
      req.body = body if body
      http.request(req)
    end
  end

  def http_delete(path, body: nil, headers: {})
    uri = URI("#{server_url}/#{path}")
    Net::HTTP.start(uri.host, uri.port) do |http|
      req = Net::HTTP::Delete.new(uri.request_uri)
      headers.each { |k, v| req[k] = v }
      req.body = body if body
      http.request(req)
    end
  end

  MockGem = Struct.new(:name, :version, :platform, :sha256, :contents, keyword_init: true) do
    def full_name
      if platform.to_s == "ruby"
        "#{name}-#{version}"
      else
        "#{name}-#{version}-#{platform}"
      end
    end
  end

  def build_test_gem(name, version, platform: nil)
    spec = Gem::Specification.new do |s|
      s.name = name
      s.version = version
      s.authors = ["Conformance"]
      s.summary = "Conformance test"
      s.files = []
      s.date = "2024-07-09"
      s.platform = platform if platform
    end
    yield spec if block_given?

    package = Gem::Package.new(StringIO.new.binmode)
    package.build_time = Time.utc(1970)
    package.spec = spec
    package.gem.singleton_class.send(:define_method, :path) { "" }
    package.build

    contents = package.gem.io.string
    MockGem.new(
      name: name,
      version: spec.version,
      platform: spec.platform,
      sha256: Digest::SHA256.hexdigest(contents),
      contents: contents
    ).tap { @all_gems << _1 }
  end

  def find_gem(full_name)
    @all_gems.reverse_each.find { _1.full_name == full_name } || raise("gem #{full_name} not found")
  end

  def advance_time(seconds)
    @time += seconds
    travel_to @time
  end

  def do_push_gem(gem, expected_code: "200")
    response = http_post("api/v1/gems",
      body: gem.contents,
      headers: {
        "Content-Type" => "application/octet-stream",
        "Content-Length" => gem.contents.bytesize.to_s,
        "Authorization" => @api_key
      })
    assert_equal expected_code, response.code, response.body
    advance_time(60)
    response
  end

  def do_yank_gem(gem, expected_code: "200")
    body = URI.encode_www_form(gem_name: gem.name, version: gem.version.to_s, platform: gem.platform)
    response = http_delete("api/v1/gems/yank",
      body: body,
      headers: {
        "Content-Type" => "application/x-www-form-urlencoded",
        "Content-Length" => body.bytesize.to_s,
        "Authorization" => @api_key
      })
    assert_equal expected_code, response.code, response.body
    advance_time(60)
    response
  end

  def do_rebuild_versions_list
    http_post("rebuild_versions_list")
    advance_time(3600)
  end

  def do_get_versions
    http_get("versions")
  end

  def do_get_names
    http_get("names")
  end

  def do_get_info(name)
    http_get("info/#{name}")
  end

  def do_get_gem(name)
    http_get("gems/#{name}.gem")
  end

  def do_get_quick_spec(name)
    http_get("quick/Marshal.4.8/#{name}.gemspec.rz")
  end

  def do_get_specs(kind = nil)
    path = [kind, "specs.4.8.gz"].compact.join("_")
    http_get(path)
  end

  def unmarshal_gzipped(body)
    Marshal.load(Zlib.gunzip(body.b))
  end

  def unmarshal_inflated(body)
    Marshal.load(Zlib.inflate(body.b))
  end

  def assert_valid_compact_index_response(response)
    assert_equal "200", response.code
    assert_equal "text/plain; charset=utf-8", response["content-type"]
    assert_equal "bytes", response["accept-ranges"]
    digest = Digest::SHA256.base64digest(response.body)
    assert_equal "sha-256=#{digest}", response["digest"]
    assert_equal "sha-256=:#{digest}:", response["repr-digest"]
    assert_equal "\"#{Digest::MD5.hexdigest(response.body)}\"", response["etag"]
  end

  def assert_pushed_gem(full_name)
    gem = find_gem(full_name)

    response = do_get_gem(full_name)
    assert_equal "200", response.code
    assert_equal gem.contents, response.body.b

    response = do_get_quick_spec(full_name)
    assert_equal "200", response.code
    actual_spec = unmarshal_inflated(response.body)
    assert_equal gem.name, actual_spec.name
    assert_equal gem.version, actual_spec.version
  end

  def assert_yanked_gem(full_name)
    gem = find_gem(full_name)

    response = do_get_gem(full_name)
    assert_includes %w[404 403], response.code
    refute_equal gem.contents, response.body.b

    response = do_get_quick_spec(full_name)
    assert_includes %w[404 403], response.code
  end

  def assert_versions_etags_match_info(versions_response)
    expected_etags = {}
    versions_response.body.each_line do |line|
      next if line.start_with?("---") || line.start_with?("created_at:")
      name, _versions, etag = line.strip.split
      next unless name && etag
      expected_etags[name] = "\"#{etag}\""
    end

    expected_etags.each do |name, expected_etag|
      info_response = do_get_info(name)
      next unless info_response.code == "200"
      assert_equal expected_etag, info_response["etag"],
        "ETag mismatch for info/#{name}"
    end
  end
end
