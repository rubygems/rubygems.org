# frozen_string_literal: true

require "test_helper"

class Api::CompactIndexTest < ActionDispatch::IntegrationTest
  setup do
    @rubygem2 = create(:rubygem, name: "gemB")
    @version = create(:version, rubygem: @rubygem2, number: "1.0.0", **checksum_attribute("v2qw2dwe"))

    @rubygem = create(:rubygem, name: "gemA")
    dep1 = create(:rubygem, name: "gemA1", indexed: true)
    dep2 = create(:rubygem, name: "gemA2", indexed: true)

    @gem_a_v1 = create(:version, rubygem: @rubygem, number: "1.0.0", required_ruby_version: nil, **checksum_attribute("v2013we2"))

    @gem_a_v2 = create(:version, rubygem: @rubygem, number: "2.0.0", required_ruby_version: nil, **checksum_attribute("v21cf94r"))
    create(:dependency, rubygem: dep1, version: @gem_a_v2)

    @gem_a_v12 = create(:version,
      rubygem: @rubygem,
      number: "1.2.0",
      **checksum_attribute("v213q4es"),
      required_rubygems_version: ">1.9",
      required_ruby_version: ">= 2.0.0")

    @gem_a_v21 = create(:version,
      rubygem: @rubygem,
      number: "2.1.0",
      required_rubygems_version: ">=2.0",
      **checksum_attribute("v2e217fz"))

    create(:dependency, rubygem: dep1, version: @gem_a_v21)
    create(:dependency, rubygem: dep2, version: @gem_a_v21)
  end

  test "/names output" do
    get names_path

    assert_response :success
    gem_names = @response.body.split("\n").drop(1)

    assert_includes gem_names, "gemA"
    assert_includes gem_names, "gemA1"
    assert_includes gem_names, "gemA2"
    assert_includes gem_names, "gemB"

    expected_digest = digest(@response.body)

    assert_equal etag(@response.body), @response.headers["ETag"]
    assert_equal "sha-256=#{expected_digest}", @response.headers["Digest"]
    assert_equal "sha-256=:#{expected_digest}:", @response.headers["Repr-Digest"]
  end

  test "/names partial response" do
    get names_path
    full_body = @response.body

    get names_path, env: { range: "bytes=15-" }

    assert_response :partial_content
    expected_digest = digest(full_body)

    assert_equal etag(full_body), @response.headers["ETag"]
    assert_equal "sha-256=#{expected_digest}", @response.headers["Digest"]
    assert_equal "sha-256=:#{expected_digest}:", @response.headers["Repr-Digest"]
    assert_equal full_body.byteslice(15..), @response.body
  end

  test "/versions serves current checksums" do
    file_contents = File.read(current_versions_file_location)

    get versions_path

    assert_response :success
    assert_match file_contents, @response.body
    assert_match(/#{versions_line(@version)}/, @response.body)
    assert_equal current_versions_surrogate_key, @response.headers["Surrogate-Key"]
  end

  test "/versions includes pre-built file and new gems" do
    file_contents = File.read(current_versions_file_location)
    gem_a_match = "#{versions_line(@gem_a_v1)}\n#{versions_line(@gem_a_v2)}\n#{versions_line(@gem_a_v12)}\n#{versions_line(@gem_a_v21)}\n"
    gem_b_match = "#{versions_line(@version)}\n"

    get versions_path
    expected_digest = digest(@response.body)

    assert_response :success
    assert_match file_contents, @response.body
    assert_match(/#{gem_b_match}#{gem_a_match}/, @response.body)
    assert_equal etag(@response.body), @response.headers["ETag"]
    assert_equal "sha-256=#{expected_digest}", @response.headers["Digest"]
    assert_equal "sha-256=:#{expected_digest}:", @response.headers["Repr-Digest"]
  end

  test "/versions partial response" do
    get versions_path
    full_response_body = @response.body
    expected_digest = digest(full_response_body)
    byte_offset = full_response_body.bytesize / 2

    get versions_path, env: { range: "bytes=#{byte_offset}-" }

    assert_response :partial_content
    assert_equal full_response_body.byteslice(byte_offset..), @response.body
    assert_equal etag(full_response_body), @response.headers["ETag"]
    assert_equal "sha-256=#{expected_digest}", @response.headers["Digest"]
    assert_equal "sha-256=:#{expected_digest}:", @response.headers["Repr-Digest"]
    assert_equal current_versions_surrogate_key, @response.headers["Surrogate-Key"]
  end

  test "/versions partial response uses current response body" do
    get versions_path
    full_response_body = @response.body
    expected_digest = digest(full_response_body)
    byte_offset = full_response_body.bytesize / 2

    get versions_path, env: { range: "bytes=#{byte_offset}-" }

    assert_response :partial_content
    assert_equal full_response_body.byteslice(byte_offset..), @response.body
    assert_equal etag(full_response_body), @response.headers["ETag"]
    assert_equal "sha-256=#{expected_digest}", @response.headers["Digest"]
    assert_equal "sha-256=:#{expected_digest}:", @response.headers["Repr-Digest"]
    assert_equal current_versions_surrogate_key, @response.headers["Surrogate-Key"]
    assert_includes full_response_body, versions_line(@version)
  end

  test "/versions updates on gem yank" do
    Deletion.create!(version: @version, user: create(:user))

    get versions_path
    full_response_body = @response.body
    expected_digest = digest(full_response_body)

    assert_response :success
    assert_includes full_response_body, "gemB -1.0.0 #{current_yanked_checksum(@version.reload)}"
    assert_equal current_versions_surrogate_key, @response.headers["Surrogate-Key"]

    byte_offset = full_response_body.bytesize / 2

    get versions_path, env: { range: "bytes=#{byte_offset}-" }

    assert_equal etag(full_response_body), @response.headers["ETag"]
    assert_equal "sha-256=#{expected_digest}", @response.headers["Digest"]
    assert_equal "sha-256=:#{expected_digest}:", @response.headers["Repr-Digest"]
    assert_equal full_response_body.byteslice(byte_offset..), @response.body
  end

  test "/version has surrogate key header" do
    get versions_path

    assert_equal current_versions_surrogate_key, @response.headers["Surrogate-Key"]
    assert_equal "max-age=3600, stale-while-revalidate=1800, stale-if-error=1800", @response.headers["Surrogate-Control"]
  end

  test "/info serves current format" do
    rubygem = create(:rubygem, name: "v2gem")
    version = create(:version, rubygem:, number: "1.0.0", created_at: Time.utc(2026, 5, 1, 12, 0, 0))

    expected = <<~VERSIONS_FILE
      ---
      1.0.0 |checksum:#{Version._sha256_hex(version.sha256)},ruby:>= 2.0.0,rubygems:>= 2.6.3,created_at:#{version.created_at.utc.iso8601}
    VERSIONS_FILE

    expected_digest = digest(expected)

    get info_path(gem_name: "v2gem")

    assert_response :success
    assert_equal expected, @response.body
    assert_equal etag(expected), @response.headers["ETag"]
    assert_equal "sha-256=#{expected_digest}", @response.headers["Digest"]
    assert_equal "sha-256=:#{expected_digest}:", @response.headers["Repr-Digest"]
    assert_equal "#{current_info_prefix}/* gem/v2gem #{current_info_prefix}/v2gem", @response.headers["Surrogate-Key"]
  end

  test "/info partial response" do
    rubygem = create(:rubygem, name: "v2partial")
    version = create(:version, rubygem:, number: "1.0.0", created_at: Time.utc(2026, 5, 1, 12, 0, 0))

    full_body = <<~VERSIONS_FILE
      ---
      1.0.0 |checksum:#{Version._sha256_hex(version.sha256)},ruby:>= 2.0.0,rubygems:>= 2.6.3,created_at:#{version.created_at.utc.iso8601}
    VERSIONS_FILE
    byte_offset = full_body.bytesize / 2
    expected_digest = digest(full_body)

    get info_path(gem_name: "v2partial"), env: { range: "bytes=#{byte_offset}-" }

    assert_response :partial_content
    assert_equal full_body.byteslice(byte_offset..), @response.body
    assert_equal etag(full_body), @response.headers["ETag"]
    assert_equal "sha-256=#{expected_digest}", @response.headers["Digest"]
    assert_equal "sha-256=:#{expected_digest}:", @response.headers["Repr-Digest"]
    assert_equal "#{current_info_prefix}/* gem/v2partial #{current_info_prefix}/v2partial", @response.headers["Surrogate-Key"]
  end

  test "/info cache expires on gem yank" do
    travel_to(Time.utc(2026, 5, 31, 12, 0, 0)) do
      rubygem = create(:rubygem, name: "v2yank")
      version = create(:version, rubygem:, number: "1.0.0", created_at: Time.utc(2026, 5, 1, 12, 0, 0))

      get info_path(gem_name: "v2yank")

      assert_response :success
      assert_includes @response.body, "1.0.0"

      Deletion.create!(version:, user: create(:user))

      get info_path(gem_name: "v2yank")

      assert_response :success
      assert_not_includes @response.body, "1.0.0"
      assert_equal "#{current_info_prefix}/* gem/v2yank #{current_info_prefix}/v2yank", @response.headers["Surrogate-Key"]
    end
  end

  test "/info with nonexistent gem" do
    get info_path(gem_name: "donotexist")

    assert_response :not_found
    assert_nil @response.headers["ETag"]
    assert_nil @response.headers["Set-Cookie"], "Expected no Set-Cookie on /info 404"
    assert_includes @response.headers["Cache-Control"], "public"
    assert_match(/max-age=60/, @response.headers["Cache-Control"])
    assert_match(/max-age=600/, @response.headers["Surrogate-Control"])
    assert_equal "#{current_info_prefix}/404 #{current_info_prefix}/donotexist", @response.headers["Surrogate-Key"]
  end

  test "/info with gzip" do
    get info_path(gem_name: "gemA"), env: { "Accept-Encoding" => "gzip" }

    assert_response :success
    assert_equal("gzip", @response.headers["Content-Encoding"])
  end

  test "/info with version having multiple dependency orders by gem name and dependency id" do
    same_dep = create(:rubygem, name: "aaab")
    create(:dependency, scope: :runtime, version: @version, rubygem: same_dep, requirements: ">= 0")
    create(:dependency, scope: :runtime, version: @version, rubygem: same_dep, requirements: "~> 0.2")

    second_dep = create(:rubygem, name: "bbcc")
    create(:dependency, version: @version, rubygem: second_dep)

    expected = <<~VERSIONS_FILE
      ---
      1.0.0 aaab:>= 0,aaab:~> 0.2,bbcc:= 1.0.0|checksum:b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78,ruby:>= 2.0.0,rubygems:>= 2.6.3,created_at:#{@version.created_at.utc.iso8601}
    VERSIONS_FILE
    expected_digest = digest(expected)

    get info_path(gem_name: "gemB")

    assert_response :success
    assert_equal expected, @response.body
    assert_equal etag(expected), @response.headers["ETag"]
    assert_equal "sha-256=#{expected_digest}", @response.headers["Digest"]
    assert_equal "sha-256=:#{expected_digest}:", @response.headers["Repr-Digest"]
  end

  private

  def etag(body)
    %("#{Digest::MD5.hexdigest(body)}")
  end

  def digest(body)
    Digest::SHA256.base64digest(body)
  end

  def current_compact_index_config
    Api::CompactIndexController::COMPACT_INDEX_VERSIONS.fetch(GemInfo::CURRENT_VERSION)
  end

  def current_versions_surrogate_key
    current_compact_index_config.fetch(:versions_surrogate_key)
  end

  def current_info_prefix
    current_compact_index_config.fetch(:info_prefix)
  end

  def current_versions_file_location
    Rails.application.config.rubygems[current_compact_index_config.fetch(:versions_file_location_key)]
  end

  def checksum_attribute(checksum)
    { GemInfo::VERSIONS.fetch(GemInfo::CURRENT_VERSION).fetch(:checksum_column) => checksum }
  end

  def current_checksum(version)
    version.public_send(GemInfo::VERSIONS.fetch(GemInfo::CURRENT_VERSION).fetch(:checksum_column))
  end

  def current_yanked_checksum(version)
    version.public_send(GemInfo::VERSIONS.fetch(GemInfo::CURRENT_VERSION).fetch(:yanked_checksum_column))
  end

  def versions_line(version)
    "#{version.rubygem.name} #{version.number} #{current_checksum(version)}"
  end
end
