require "tempfile"
require "test_helper"

class CompactIndexTest < ActionDispatch::IntegrationTest
  def etag(body)
    '"' << Digest::MD5.hexdigest(body) << '"'
  end

  setup do
    @rubygem2 = create(:rubygem, name: "gemB")
    @version = create(:version, rubygem: @rubygem2, number: "1.0.0", info_checksum: "qw2dwe")

    # another gem
    rubygem = create(:rubygem, name: "gemA")
    dep1 = create(:rubygem, name: "gemA1")
    dep2 = create(:rubygem, name: "gemA2")

    # minimal version
    create(:version,
      rubygem: rubygem,
      number: "1.0.0",
      info_checksum: "013we2",
      required_ruby_version: nil)

    # version with deps but no ruby or rubygems requirements
    version = create(:version,
      rubygem: rubygem,
      number: "2.0.0",
      info_checksum: "1cf94r",
      required_ruby_version: nil)
    create(:dependency, rubygem: dep1, version: version)

    # version with required ruby and rubygems version
    create(:version,
      rubygem: rubygem,
      number: "1.2.0",
      info_checksum: "13q4es",
      required_rubygems_version: ">1.9",
      required_ruby_version: ">= 2.0.0")

    # version with everything
    version = create(:version,
      rubygem: rubygem,
      number: "2.1.0",
      info_checksum: "e217fz",
      required_rubygems_version: ">=2.0")

    create(:dependency, rubygem: dep1, version: version)
    create(:dependency, rubygem: dep2, version: version)
  end

  teardown do
    Rails.cache.clear
  end

  test "/names output" do
    get names_path

    assert_response :success
    expected_body = "---\ngemA\ngemA1\ngemA2\ngemB\n"
    assert_equal expected_body, @response.body
    assert_equal etag(expected_body), @response.headers["ETag"]
    assert_equal %w[gemA gemA1 gemA2 gemB], Rails.cache.read("names")
  end

  test "/names partial response" do
    get names_path, env: { range: "bytes=15-" }

    assert_response 206
    full_body = "---\ngemA\ngemA1\ngemA2\ngemB\n"
    assert_equal etag(full_body), @response.headers["ETag"]
    assert_equal "gemA2\ngemB\n", @response.body
  end

  test "/versions includes pre-built file and new gems" do
    versions_file_location = Rails.application.config.rubygems["versions_file_location"]
    file_contents = File.read(versions_file_location)
    gem_a_match = "gemA 1.0.0 013we2\ngemA 2.0.0 1cf94r\ngemA 1.2.0 13q4es\ngemA 2.1.0 e217fz\n"
    gem_b_match = "gemB 1.0.0 qw2dwe\n"

    get versions_path
    assert_response :success
    assert_match file_contents, @response.body
    assert_match(/#{gem_b_match}#{gem_a_match}/, @response.body)
    assert_equal etag(@response.body), @response.headers["ETag"]
  end

  test "/versions partial response" do
    get versions_path
    full_response_body = @response.body
    partial_body = "1.0.0 013we2\ngemA 2.0.0 1cf94r\ngemA 1.2.0 13q4es\ngemA 2.1.0 e217fz\n"

    get versions_path, env: { range: "bytes=229-" }

    assert_response 206
    assert_equal partial_body, @response.body
    assert_equal etag(full_response_body), @response.headers["ETag"]
  end

  test "/versions updates on gem yank" do
    Deletion.create!(version: @version, user: create(:user))
    expected = <<~VERSIONS_FILE
      gemB 1.0.0 qw2dwe
      gemA 1.0.0 013we2
      gemA 2.0.0 1cf94r
      gemA 1.2.0 13q4es
      gemA 2.1.0 e217fz
      gemB -1.0.0 6105347ebb9825ac754615ca55ff3b0c
    VERSIONS_FILE

    get versions_path
    full_response_body = @response.body
    get versions_path, env: { range: "bytes=206-" }
    assert_equal etag(full_response_body), @response.headers["ETag"]
    assert_equal expected, @response.body
  end

  test "/version has surrogate key header" do
    get versions_path
    assert_equal "versions", @response.headers["Surrogate-Key"]
    assert_equal "max-age=30", @response.headers["Surrogate-Control"]
  end

  test "/info with existing gem" do
    expected = <<~VERSIONS_FILE
      ---
      1.0.0 |checksum:b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78,rubygems:>= 2.6.3
      2.0.0 gemA1:= 1.0.0|checksum:b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78,rubygems:>= 2.6.3
      1.2.0 |checksum:b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78,ruby:>= 2.0.0,rubygems:>1.9
      2.1.0 gemA1:= 1.0.0,gemA2:= 1.0.0|checksum:b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78,ruby:>= 2.0.0,rubygems:>=2.0
    VERSIONS_FILE

    get info_path(gem_name: "gemA")

    assert_response :success
    assert_equal expected, @response.body
    assert_equal etag(expected), @response.headers["ETag"]
    assert_equal expected, CompactIndex.info(Rails.cache.read("info/gemA"))
  end

  test "/info has surrogate key header" do
    get info_path(gem_name: "gemA")
    assert_equal "info/* gem/gemA info/gemA", @response.headers["Surrogate-Key"]
  end

  test "/info partial response" do
    expected = <<~VERSIONS_FILE
      ---
      1.0.0 |checksum:b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78,rubygems:>= 2.6.3
      2.0.0 gemA1:= 1.0.0|checksum:b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78,rubygems:>= 2.6.3
      1.2.0 |checksum:b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78,ruby:>= 2.0.0,rubygems:>1.9
      2.1.0 gemA1:= 1.0.0,gemA2:= 1.0.0|checksum:b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78,ruby:>= 2.0.0,rubygems:>=2.0
    VERSIONS_FILE

    get info_path(gem_name: "gemA"), env: { range: "bytes=159-" }

    assert_response 206
    assert_equal expected[159..], @response.body
  end

  test "/info with new gem" do
    rubygem = create(:rubygem, name: "gemC")
    version = create(:version, rubygem: rubygem, number: "1.0.0", info_checksum: "65ea0d")
    create(:dependency, :development, version: version, rubygem: @rubygem2)
    expected = <<~VERSIONS_FILE
      ---
      1.0.0 |checksum:b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78,ruby:>= 2.0.0,rubygems:>= 2.6.3
    VERSIONS_FILE

    get info_path(gem_name: "gemC")

    assert_response :success
    assert_equal(expected, @response.body)
    assert_equal etag(expected), @response.headers["ETag"]
  end

  test "/info with nonexistent gem" do
    get info_path(gem_name: "donotexist")
    assert_response :not_found
    assert_nil @response.headers["ETag"]
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
      1.0.0 aaab:>= 0,aaab:~> 0.2,bbcc:= 1.0.0|checksum:b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78,ruby:>= 2.0.0,rubygems:>= 2.6.3
    VERSIONS_FILE

    get info_path(gem_name: "gemB")
    assert_response :success
    assert_equal(expected, @response.body)
    assert_equal etag(expected), @response.headers["ETag"]
  end
end
