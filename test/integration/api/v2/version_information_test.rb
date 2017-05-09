require 'test_helper'

class VersionInformationTest < ActionDispatch::IntegrationTest
  setup do
    @rubygem = create(:rubygem)
    create(:version, rubygem: @rubygem, number: '2.0.0')
  end

  def request_endpoint(rubygem, version, format = 'json')
    get api_v2_rubygem_version_path(rubygem.name, version, format: format)
  end

  test "return gem version" do
    request_endpoint(@rubygem, '2.0.0')
    assert_response :success
    json_response = JSON.load(@response.body)
    assert_kind_of Hash, json_response
    assert_equal '2.0.0', json_response["number"]
  end

  test "has required fields" do
    request_endpoint(@rubygem, '2.0.0')
    json_response = JSON.load(@response.body)
    json_response["sha"]
    json_response["platform"]
    json_response["ruby_version"]
  end

  test "version does not exist" do
    request_endpoint(@rubygem, '1.2.3')
    assert_response :not_found
    assert_equal "This version could not be found.", @response.body
  end

  test "gem does not exist" do
    request_endpoint(Rubygem.new(name: "nonexistent_gem"), '2.0.0')
    assert_response :not_found
    assert_equal "This gem could not be found", @response.body
  end

  test "second get returns not modified" do
    request_endpoint(@rubygem, '2.0.0')
    assert_response :success
    get api_v2_rubygem_version_path(@rubygem.name, '2.0.0', format: 'json'), headers: {
      "HTTP_IF_MODIFIED_SINCE" => @response.headers['Last-Modified'],
      "HTTP_IF_NONE_MATCH" => @response.etag
    }
    assert_response :not_modified
  end

  test "rubygem has .(dot) in name" do
    @rubygem.update_attribute(:name, "ruby.ruby.ruby")
    request_endpoint(@rubygem, '2.0.0')
    assert_response :success
    json_response = JSON.load(@response.body)
    assert_equal '2.0.0', json_response["number"]
  end
end
