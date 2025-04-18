require "test_helper"

class EncodingTest < ActionDispatch::IntegrationTest
  include SearchKickHelper

  test "invalid utf-8 characters should be sanitized" do
    import_and_refresh

    get "/api/v1/search.json?query=vagrant%ADvbguest"

    assert_response :success
  end

  test "gzip not supported" do
    get "/"

    assert_response :success
    assert_nil @response.headers["Content-Encoding"]
  end
end
