require "test_helper"

class Api::V1::Search < ActionDispatch::IntegrationTest
  test "request with non-string query shows bad request" do
    get "/api/v1/search.json?query[]="
    assert_response :bad_request
  end
end
