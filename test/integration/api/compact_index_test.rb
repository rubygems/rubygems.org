require 'tempfile'
require 'test_helper'

class CompactIndexTest < ActionDispatch::IntegrationTest
  setup do
    rubygem = create(:rubygem, name: 'gemA')
    dep1 = create(:rubygem, name: 'gemA1')
    dep2 = create(:rubygem, name: 'gemA2')

    # minimal version
    create(:version,
      rubygem: rubygem,
      number: '1.0.0',
      info_checksum: '013we2',
      required_ruby_version: nil)

    # version with required ruby and rubygems version
    create(:version,
      rubygem: rubygem,
      number: '1.2.0',
      info_checksum: '13q4es',
      required_rubygems_version: ">1.9",
      required_ruby_version: ">= 2.0.0")

    # version with deps but no ruby or rubygems requirements
    version = create(:version,
      rubygem: rubygem,
      number: '2.0.0',
      info_checksum: '1cf94r',
      required_ruby_version: nil)
    create(:dependency, rubygem: dep1, version: version)

    # version with everything
    version = create(:version,
      rubygem: rubygem,
      number: '2.1.0',
      info_checksum: 'e217fz',
      required_rubygems_version: ">=2.0")

    create(:dependency, rubygem: dep1, version: version)
    create(:dependency, rubygem: dep2, version: version)

    # other gem
    @rubygem2 = create(:rubygem, name: 'gemB')
    create(:version, rubygem: @rubygem2, number: '1.0.0', info_checksum: 'qw2dwe')
  end

  teardown do
    Rails.cache.clear
  end

  test "/names output" do
    get names_path
    assert_response :success
    assert_equal "---\ngemA\ngemA1\ngemA2\ngemB\n", @response.body
    assert_equal %w(gemA gemA1 gemA2 gemB), Rails.cache.read('names')
  end

  test "/names partial response" do
    get names_path, nil, range: "bytes=15-"
    assert_response 206
    assert_equal "gemA2\ngemB\n", @response.body
  end

  test "/versions returns pre-built versions file" do
    get versions_path
    assert_response :success

    versions_file_location = Rails.application.config.rubygems['versions_file_location']
    file_contents = File.open(versions_file_location).read
    assert_match file_contents, @response.body
    gem_a_match = /gemA 1.2.0 13q4es\ngemA 2.0.0 1cf94r\ngemA 2.1.0 e217fz\n/
    gem_b_match = /gemB 1.0.0 qw2dwe\n/
    assert_match(/#{gem_a_match}#{gem_b_match}/, @response.body)
    assert_not_nil Rails.cache.read('versions')
  end

  test "/versions with new gem" do
    rubygem = create(:rubygem, name: 'gemC')
    create(:version, rubygem: rubygem, number: '1.0.0', info_checksum: '65ea0d')
    get versions_path
    assert_response :success
    assert_match(/gemC 1.0.0 65ea0d\n$/, @response.body)
  end

  test "/versions extra gems are ordered by creation time" do
    rubygem = create(:rubygem, name: 'ZZZ')
    create(:version, rubygem: rubygem, number: '1.0.0', info_checksum: 'a8a851')

    rubygem = create(:rubygem, name: 'AAA')
    create(:version, rubygem: rubygem, number: '1.0.0', info_checksum: '6abdc2')

    get versions_path
    assert_response :success
    assert_match(/ZZZ 1.0.0 a8a851\nAAA/, @response.body)
  end

  test "/versions partial response" do
    get versions_path, nil, range: "bytes=229-"
    assert_response 206
    assert_equal "gemA 2.0.0 1cf94r\ngemA 2.1.0 e217fz\ngemB 1.0.0 qw2dwe\n", @response.body
  end

  test "/info with existing gem" do
    get info_path(gem_name: 'gemA')
    assert_response :success
    response = <<-eos
---
1.0.0 |checksum:b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78,rubygems:>= 2.6.3
1.2.0 |checksum:b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78,ruby:>= 2.0.0,rubygems:>1.9
2.0.0 gemA1:= 1.0.0|checksum:b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78,rubygems:>= 2.6.3
2.1.0 gemA1:= 1.0.0,gemA2:= 1.0.0|checksum:b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78,ruby:>= 2.0.0,rubygems:>=2.0
eos
    assert_equal response, @response.body
    assert_equal response, CompactIndex.info(Rails.cache.read("info/gemA"))
  end

  test "/info with new gem" do
    rubygem = create(:rubygem, name: 'gemC')
    version = create(:version, rubygem: rubygem, number: '1.0.0', info_checksum: '65ea0d')
    create(:dependency, :development, version: version, rubygem: @rubygem2)
    get info_path(gem_name: 'gemC')
    assert_response :success
    expected = <<-END
---
1.0.0 |checksum:b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78,ruby:>= 2.0.0,rubygems:>= 2.6.3
END
    assert_equal(expected, @response.body)
  end

  test "/info with nonexistent gem" do
    get info_path(gem_name: 'donotexist')
    assert_response :not_found
  end

  test "/info partial response" do
    get info_path(gem_name: 'gemA'), nil, range: "bytes=159-"
    assert_response 206
    response = <<-eos
04f7a26e716e0a1e2789df78,ruby:>= 2.0.0,rubygems:>1.9
2.0.0 gemA1:= 1.0.0|checksum:b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78,rubygems:>= 2.6.3
2.1.0 gemA1:= 1.0.0,gemA2:= 1.0.0|checksum:b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78,ruby:>= 2.0.0,rubygems:>=2.0
eos
    assert_equal response, @response.body
  end
end
