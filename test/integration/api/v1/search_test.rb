require "test_helper"

class Api::V1::Search < ActionDispatch::IntegrationTest
  include SearchKickHelper

  test "request with non-string query shows bad request" do
    import_and_refresh

    get "/api/v1/search.json?query[]="

    assert_response :bad_request
  end
end
