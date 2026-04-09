# frozen_string_literal: true

require "application_system_test_case"

require_relative "../../lib/gemcutter/middleware/hostess"

class GemServerConformanceTest < ApplicationSystemTestCase
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

    test = self
    Rails.application.routes.disable_clear_and_finalize = true
    Rails.application.routes.draw do
      post "/set_time", to: lambda { |env|
        test.travel_to Time.iso8601(Rack::Request.new(env).body.read)
        [200, {}, ["OK"]]
      }
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
  end

  teardown do
    ActiveSupport::Notifications.unsubscribe(@subscriber)
    Rails.application.reload_routes!
  end

  test "is a conformant gem server" do
    create(:api_key, scopes: %w[push_rubygem yank_rubygem], key: "12345")

    output, status = Open3.capture2e(
      {
        "UPSTREAM" => "http://#{Capybara.current_session.config.server_host}:#{Capybara.current_session.config.server_port}",
        "GEM_HOST_API_KEY" => "12345"
      },
      "gem_server_conformance",
      "--fail-fast", "--tag=~content_type_header", "--tag=~content_length_header"
    )

    assert_predicate status, :success?, output
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
