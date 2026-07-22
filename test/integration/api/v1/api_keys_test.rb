# frozen_string_literal: true

require "test_helper"

# Must be an integration test: the cache headers come from the Rack middleware
# stack, which ActionController::TestCase does not run.
class Api::V1::ApiKeysTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @auth = ActionController::HttpAuthentication::Basic.encode_credentials(@user.email, @user.password)
  end

  # GET /api/v1/api_key (the `gem signin` mint endpoint) is retired: 410 Gone, mints nothing, for
  # any method or credential state.
  should "return 410 Gone and mint nothing on an authenticated GET" do
    assert_no_difference -> { @user.api_keys.count } do
      get "/api/v1/api_key", headers: { "HTTP_AUTHORIZATION" => @auth }
    end

    assert_response :gone
    assert_match "retired", @response.body
  end

  should "return 410 Gone without credentials" do
    get "/api/v1/api_key"

    assert_response :gone
  end

  should "return 410 Gone and mint nothing on HEAD" do
    assert_no_difference -> { @user.api_keys.count } do
      head "/api/v1/api_key", headers: { "HTTP_AUTHORIZATION" => @auth }
    end

    assert_response :gone
  end

  # Key minting moved to POST /api/v1/api_key (create), which still returns a secret — so the
  # Rack::Deflater / cache-header regression lives here now: a minted key must never be
  # shared/edge-cacheable, even when gzip-encoded.
  should "not allow shared caching of a minted key when the client accepts gzip" do
    post "/api/v1/api_key",
      params: { name: "ci-key", index_rubygems: "true" },
      headers: { "HTTP_AUTHORIZATION" => @auth, "HTTP_ACCEPT_ENCODING" => "gzip" }

    assert_response :success
    assert_equal "gzip", @response.headers["Content-Encoding"]

    cache_control = @response.headers["Cache-Control"].to_s

    assert_includes cache_control, "private", "got #{cache_control.inspect}"
    assert_includes cache_control, "no-store", "got #{cache_control.inspect}"
    assert_equal "max-age=0", @response.headers["Surrogate-Control"]
    assert_includes @response.headers["Vary"].to_s, "Authorization", "got #{@response.headers['Vary'].inspect}"
  end
end
