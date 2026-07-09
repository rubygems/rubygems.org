# frozen_string_literal: true

require "test_helper"

# Must be an integration test: the cache headers come from the Rack middleware
# stack, which ActionController::TestCase does not run.
class Api::V1::ProfilesTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @auth = ActionController::HttpAuthentication::Basic.encode_credentials(@user.email, @user.password)
  end

  should "not allow shared caching of a private profile when the client accepts gzip" do
    get "/api/v1/profile/me.yaml",
      headers: { "HTTP_AUTHORIZATION" => @auth, "HTTP_ACCEPT_ENCODING" => "gzip" }

    assert_response :success
    assert_equal "gzip", @response.headers["Content-Encoding"]

    cache_control = @response.headers["Cache-Control"].to_s

    assert_includes cache_control, "private", "got #{cache_control.inspect}"
    assert_includes cache_control, "no-store", "got #{cache_control.inspect}"
    assert_equal "max-age=0", @response.headers["Surrogate-Control"]
    assert_includes @response.headers["Vary"].to_s, "Authorization", "got #{@response.headers['Vary'].inspect}"
  end

  should "not allow shared caching of a private profile without gzip" do
    get "/api/v1/profile/me.yaml", headers: { "HTTP_AUTHORIZATION" => @auth }

    assert_response :success

    cache_control = @response.headers["Cache-Control"].to_s

    assert_includes cache_control, "private", "got #{cache_control.inspect}"
    assert_includes cache_control, "no-store", "got #{cache_control.inspect}"
    assert_equal "max-age=0", @response.headers["Surrogate-Control"]
    assert_includes @response.headers["Vary"].to_s, "Authorization", "got #{@response.headers['Vary'].inspect}"
  end

  should "keep the public profile cacheable" do
    get "/api/v1/profiles/#{@user.handle}.json"

    assert_response :success
    cache_control = @response.headers["Cache-Control"].to_s

    refute_includes cache_control, "no-store", "got #{cache_control.inspect}"
  end
end
