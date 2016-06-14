require 'tempfile'
require 'test_helper'

class CompactIndexTest < ActionDispatch::IntegrationTest
  setup do
    @rubygem = create(:rubygem, name: 'gemA')
    @dep1 = create(:rubygem, name: 'gemA1')
    @dep2 = create(:rubygem, name: 'gemA2')

    # minimal version
    create(
      :version, rubygem: @rubygem, number: '1.0.0', sha256: 'checksum1', required_ruby_version: nil
    )

    # version with required ruby and rubygems version
    create(
      :version, rubygem: @rubygem, number: '1.2.0', sha256: 'checksum1', required_rubygems_version: ">1.9"
    )

    # version with deps but no ruby or rubygems requirements
    version = create(
      :version, rubygem: @rubygem, number: '2.0.0', sha256: 'checksum2', required_ruby_version: nil
    )
    create(:dependency, rubygem: @dep1, version: version)

    # version with everything
    version = create(
      :version, rubygem: @rubygem, number: '2.1.0', sha256: 'checksum2', required_rubygems_version: ">=2.0"
    )
    create(:dependency, rubygem: @dep1, version: version)
    create(:dependency, rubygem: @dep2, version: version)

    # other gem
    @rubygem2 = create(:rubygem, name: 'gemB')
    create(:version, rubygem: @rubygem2, number: '1.0.0')
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

  test "/versions output" do
    get versions_path
    assert_response :success

    versions_file_location = Rails.application.config.rubygems['versions_file_location']
    file_contents = File.open(versions_file_location).read
    assert_match file_contents, @response.body
    gem_a_match = /gemA 1.0.0 \ngemA 1.2.0 \ngemA 2.0.0 \ngemA 2.1.0 \n/
    gem_b_match = /gemB 1.0.0 \n/
    assert_match(/#{gem_a_match}#{gem_b_match}/, @response.body)
    assert_not_nil Rails.cache.read('versions')
  end

  test "/versions with new gem" do
    rubygem = create(:rubygem, name: 'gemC')
    create(:version, rubygem: rubygem, number: '1.0.0')
    get versions_path
    assert_response :success
    assert_match(/gemC 1.0.0 \n$/, @response.body)
  end

  test "/versions extra gems are ordered by creation time" do
    rubygem = create(:rubygem, name: 'ZZZ')
    create(:version, rubygem: rubygem, number: '1.0.0')

    rubygem = create(:rubygem, name: 'AAA')
    create(:version, rubygem: rubygem, number: '1.0.0')

    get versions_path
    assert_response :success
    assert_match(/ZZZ 1.0.0 \nAAA/, @response.body)
  end

  test "/versions partial response" do
    get versions_path, nil, range: "bytes=200-"
    assert_response 206
    assert_equal "0.0 \ngemA 1.2.0 \ngemA 2.0.0 \ngemA 2.1.0 \ngemB 1.0.0 \n", @response.body
  end

  test "/info with existing gem" do
    get info_path(gem_name: @rubygem.name)
    assert_response :success
    response = <<-eos
---
1.0.0 |checksum:checksum1,rubygems:>= 2.6.3
1.2.0 |checksum:checksum1,ruby:>= 2.0.0,rubygems:>1.9
2.0.0 gemA1:= 1.0.0|checksum:checksum2,rubygems:>= 2.6.3
2.1.0 gemA1:= 1.0.0,gemA2:= 1.0.0|checksum:checksum2,ruby:>= 2.0.0,rubygems:>=2.0
eos
    assert_equal response, @response.body
    assert_equal response, CompactIndex.info(Rails.cache.read("info/#{@rubygem.name}"))
  end

  test "/info with unexisting gem" do
    get info_path(gem_name: 'donotexist')
    assert_response :not_found
  end

  test "/info partial response" do
    get info_path(gem_name: @rubygem.name), nil, range: "bytes=159-"
    assert_response 206
    assert_equal "2.1.0 gemA1:= 1.0.0,gemA2:= 1.0.0|checksum:checksum2,ruby:>= 2.0.0,rubygems:>=2.0\n", @response.body
  end
end
