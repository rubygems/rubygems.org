# frozen_string_literal: true

require "test_helper"

# Must be an integration test: the cache headers come from the Rack middleware
# stack, which ActionController::TestCase does not run.
class Api::V1::ApiKeysTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @auth = ActionController::HttpAuthentication::Basic.encode_credentials(@user.email, @user.password)
  end

  should "not allow shared caching of a minted key when the client accepts gzip" do
    get "/api/v1/api_key",
      headers: { "HTTP_AUTHORIZATION" => @auth, "HTTP_ACCEPT_ENCODING" => "gzip" }

    assert_response :success
    assert_equal "gzip", @response.headers["Content-Encoding"]

    cache_control = @response.headers["Cache-Control"].to_s

    assert_includes cache_control, "private", "got #{cache_control.inspect}"
    assert_includes cache_control, "no-store", "got #{cache_control.inspect}"
    assert_equal "max-age=0", @response.headers["Surrogate-Control"]
    assert_includes @response.headers["Vary"].to_s, "Authorization", "got #{@response.headers['Vary'].inspect}"
  end

  should "not allow shared caching of a minted key without gzip" do
    get "/api/v1/api_key", headers: { "HTTP_AUTHORIZATION" => @auth }

    assert_response :success

    cache_control = @response.headers["Cache-Control"].to_s

    assert_includes cache_control, "private", "got #{cache_control.inspect}"
    assert_includes cache_control, "no-store", "got #{cache_control.inspect}"
    assert_equal "max-age=0", @response.headers["Surrogate-Control"]
    assert_includes @response.headers["Vary"].to_s, "Authorization", "got #{@response.headers['Vary'].inspect}"
  end

  should "not mint a key on an authenticated HEAD" do
    assert_no_difference -> { @user.api_keys.count } do
      head "/api/v1/api_key", headers: { "HTTP_AUTHORIZATION" => @auth }
    end

    assert_response :success
  end

  should "still mint a key on GET" do
    assert_difference -> { @user.api_keys.count }, 1 do
      get "/api/v1/api_key", headers: { "HTTP_AUTHORIZATION" => @auth }
    end

    assert_response :success
  end

  should "challenge an unauthenticated HEAD like GET" do
    assert_no_difference -> { @user.api_keys.count } do
      head "/api/v1/api_key"
    end

    assert_response :unauthorized
  end
end
