require "test_helper"

class IpSpoofingTest < ActionDispatch::IntegrationTest
  test "request with Client-IP and X-Forwarded-For header mismatch responds with bad request" do
    get "/", headers: { HTTP_CLIENT_IP: "172.16.72.122", HTTP_X_FORWARDED_FOR: "8.8.8.8, 8.8.8.8" }
    assert_response :bad_request
  end
end
