require "test_helper"

class Api::V1::RubygemsTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
  end

  test "request has remote addr present" do
    ip_address = "1.2.3.4"
    RackAttackReset.expects(:gem_push_backoff).with(ip_address).once

    post "/api/v1/gems",
          params: gem_file("test-1.0.0.gem").read,
          headers: { REMOTE_ADDR: ip_address, HTTP_AUTHORIZATION: @user.api_key, CONTENT_TYPE: "application/octet-stream" }

    assert_response :success
  end

  test "request has remote addr absent" do
    RackAttackReset.expects(:gem_push_backoff).never

    post "/api/v1/gems",
          params: gem_file("test-1.0.0.gem").read,
          headers: { REMOTE_ADDR: "", HTTP_AUTHORIZATION: @user.api_key, CONTENT_TYPE: "application/octet-stream" }

    assert_response :success
  end
end
