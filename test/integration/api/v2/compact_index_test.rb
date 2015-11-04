require 'tempfile'
require 'test_helper'

class CompactIndexTest < ActionDispatch::IntegrationTest
  setup do
    @rubygem = create(:rubygem, name: 'gemA')
    @dep1 = create(:rubygem, name: 'gemA1')
    @dep2 = create(:rubygem, name: 'gemA2')

    # minimal version
    create(
      :version, rubygem: @rubygem, number: '1.0.0', sha256: 'checksum1', ruby_version: nil
    )

    # version with required ruby and rubygems version
    create(
      :version, rubygem: @rubygem, number: '1.2.0', sha256: 'checksum1', rubygems_version: ">1.9"
    )

    # version with deps but no ruby or rubygems requirements
    version = create(
      :version, rubygem: @rubygem, number: '2.0.0', sha256: 'checksum2', ruby_version: nil
    )
    create(:dependency, rubygem: @dep1, version: version)

    # version with everything
    version = create(
      :version, rubygem: @rubygem, number: '2.1.0', sha256: 'checksum2', rubygems_version: ">=2.0"
    )
    create(:dependency, rubygem: @dep1, version: version)
    create(:dependency, rubygem: @dep2, version: version)

    # other gem
    @rubygem2 = create(:rubygem, name: 'gemB')
    create(:version, rubygem: @rubygem2, number: '1.0.0')
  end

  test "/names output" do
    get api_v2_names_path
    assert_response :success
    assert_equal "---\ngemA\ngemA1\ngemA2\ngemB\n", @response.body
  end

  test "/versions output" do
    get api_v2_versions_path
    assert_response :success

    file_contents = File.open("config/versions.list").read
    assert_match file_contents, @response.body
    gem_a_match = /gemA 1.0.0 \w+\ngemA 1.2.0 \w+\ngemA 2.0.0 \w+\ngemA 2.1.0 \w+\n/
    gem_b_match = /gemB 1.0.0 \w+\n/
    assert_match(/#{gem_a_match}#{gem_b_match}/, @response.body)
  end

  test "/versions with new gem" do
    rubygem = create(:rubygem, name: 'gemC')
    create(:version, rubygem: rubygem, number: '1.0.0')
    get api_v2_versions_path
    assert_response :success
    assert_match(/gemC 1.0.0 \w+\n$/, @response.body)
  end

  test "/versions extra gems are ordered by creation time" do
    rubygem = create(:rubygem, name: 'ZZZ')
    create(:version, rubygem: rubygem, number: '1.0.0')

    rubygem = create(:rubygem, name: 'AAA')
    create(:version, rubygem: rubygem, number: '1.0.0')

    get api_v2_versions_path
    assert_response :success
    assert_match(/ZZZ 1.0.0 \w+\nAAA/, @response.body)
  end

  test "/info with existing gem" do
    get api_v2_info_path(gem_name: @rubygem.name)
    assert_response :success
    assert_equal "---\n" \
      "1.0.0 |checksum:checksum1\n" \
      "1.2.0 |checksum:checksum1,ruby:>= 2.0.0,rubygems:>1.9\n" \
      "2.0.0 gemA1:= 1.0.0|checksum:checksum2\n" \
      "2.1.0 gemA1:= 1.0.0,gemA2:= 1.0.0|checksum:checksum2,ruby:>= 2.0.0,rubygems:>=2.0\n",
      @response.body
  end

  test "/info with unexisting gem" do
    get api_v2_info_path(gem_name: 'donotexist')
    assert_response :not_found
  end
end
