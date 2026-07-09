# frozen_string_literal: true

require "test_helper"

class Api::V1::RubygemsTest < ActionDispatch::IntegrationTest
  setup do
    @key = "12345"
    @user = create(:user)
    create(:api_key, owner: @user, key: @key, scopes: %i[index_rubygems push_rubygem])
  end

  test "request has remote addr present" do
    ip_address = "1.2.3.4"
    RackAttackReset.expects(:gem_push_backoff).with(ip_address, @user.to_gid).once

    post "/api/v1/gems",
          params: gem_file("test-1.0.0.gem", &:read),
          headers: { REMOTE_ADDR: ip_address, HTTP_AUTHORIZATION: @key, CONTENT_TYPE: "application/octet-stream" }

    assert_response :success
  end

  test "request has remote addr absent" do
    RackAttackReset.expects(:gem_push_backoff).never

    post "/api/v1/gems",
          params: gem_file("test-1.0.0.gem", &:read),
          headers: { REMOTE_ADDR: "", HTTP_AUTHORIZATION: @key, CONTENT_TYPE: "application/octet-stream" }

    assert_response :success
  end

  test "does not allow shared caching of the authenticated gem index" do
    get "/api/v1/gems.json",
          headers: { HTTP_AUTHORIZATION: @key, HTTP_ACCEPT_ENCODING: "gzip" }

    assert_response :success
    assert_equal "gzip", @response.headers["Content-Encoding"]

    cache_control = @response.headers["Cache-Control"].to_s

    assert_includes cache_control, "private", "got #{cache_control.inspect}"
    assert_includes cache_control, "no-store", "got #{cache_control.inspect}"
    assert_equal "max-age=0", @response.headers["Surrogate-Control"]
    assert_includes @response.headers["Vary"].to_s, "Authorization", "got #{@response.headers['Vary'].inspect}"
  end
end
