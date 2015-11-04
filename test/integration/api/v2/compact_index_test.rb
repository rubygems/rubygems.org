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
end
