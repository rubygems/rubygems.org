require "test_helper"

class ApiPageParamsTest < ActionDispatch::IntegrationTest
  include SearchKickHelper

  test "api search with page smaller than 1" do
    create(:rubygem, name: "some", number: "1.0.0")
    import_and_refresh

    get api_v1_search_path(page: "0", query: "some", format: :json)

    assert_redirected_to api_v1_search_path(page: "1", query: "some", format: :json)
    follow_redirect!
    refute_empty response.parsed_body
  end

  test "api search with page is not a numer" do
    create(:rubygem, name: "some", number: "1.0.0")
    import_and_refresh

    get api_v1_search_path(page: "foo", query: "some", format: :json)

    assert_redirected_to api_v1_search_path(page: "1", query: "some", format: :json)
    follow_redirect!
    refute_empty response.parsed_body
  end

  test "api search with page that can't be converted to a number" do
    create(:rubygem, name: "some", number: "1.0.0")
    import_and_refresh

    get api_v1_search_path(page: { "$acunetix" => "1" }, query: "some", format: :json)

    assert_redirected_to api_v1_search_path(page: "1", query: "some", format: :json)
    follow_redirect!
    refute_empty response.parsed_body
  end
end
