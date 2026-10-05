# frozen_string_literal: true

require "test_helper"

# Regression guard for ApplicationController#deny_shared_cache_when_authenticated, both
# directions: anonymous/public responses stay cacheable (gate doesn't fire), and authenticated
# responses are private, no-store even on a normally-public page. The api_key path
# (dashboard.atom) is covered in test/functional/dashboards_controller_test.rb.
class AuthenticatedCacheHeadersTest < ActionDispatch::IntegrationTest
  test "anonymous public response is not marked no-store, so it stays cacheable" do
    get "/"

    assert_response :success
    refute_includes response.headers["Cache-Control"].to_s, "no-store"
  end

  test "signed-in response is marked private, no-store across any controller" do
    user = create(:user, remember_token_expires_at: Gemcutter::REMEMBER_FOR.from_now)
    post session_path(session: { who: user.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })

    get dashboard_path

    assert_response :success
    assert_equal "private, no-store", response.headers["Cache-Control"]
    assert_equal "max-age=0", response.headers["Surrogate-Control"]
    # Vary must key on identity — Authorization/Cookie absent from Vary was the GHSA root cause.
    assert_includes response.headers["Vary"].to_s, "Authorization", "got #{response.headers['Vary'].inspect}"
    assert_includes response.headers["Vary"].to_s, "Cookie", "got #{response.headers['Vary'].inspect}"
  end

  test "signed-in request to a normally-public, CDN-cached page is flipped to private, no-store" do
    # `/` (home#index) is CDN-cacheable for anonymous users (asserted above). A signed-in
    # user must NOT get a shared-cacheable response for the same URL, so the after_action
    # overrides it to private/no-store: the secure-by-default guarantee on public pages.
    user = create(:user, remember_token_expires_at: Gemcutter::REMEMBER_FOR.from_now)
    post session_path(session: { who: user.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })

    get "/"

    assert_response :success
    assert_equal "private, no-store", response.headers["Cache-Control"]
    assert_equal "max-age=0", response.headers["Surrogate-Control"]
  end

  # Public API actions call cache_expiry_headers (expires_in public: true) regardless of
  # sign-in. expires_in writes response.cache_control, which Rails merges over the raw
  # Cache-Control header at commit time, so the guard must win in that merge too.
  test "anonymous public API response stays public" do
    rubygem = create(:rubygem, name: "cachetest", number: "1.0.0")

    get "/api/v1/gems/#{rubygem.name}.json"

    assert_response :success
    assert_equal "max-age=60, public", response.headers["Cache-Control"]
    assert_includes response.headers["Surrogate-Control"], "max-age=3600"
  end

  test "signed-in public API response is private, no-store despite expires_in public" do
    rubygem = create(:rubygem, name: "cachetest", number: "1.0.0")
    user = create(:user, remember_token_expires_at: Gemcutter::REMEMBER_FOR.from_now)
    post session_path(session: { who: user.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })

    get "/api/v1/gems/#{rubygem.name}.json"

    assert_response :success
    assert_includes response.headers["Set-Cookie"].to_s, "remember_token"
    assert_equal "private, no-store", response.headers["Cache-Control"]
    assert_equal "max-age=0", response.headers["Surrogate-Control"]
    assert_includes response.headers["Vary"].to_s, "Cookie"
  end

  test "anonymous request to a login-gated page redirects to sign-in and is not edge-cacheable" do
    # redirect_to_signin fires for anonymous users, where the authenticated guard does NOT
    # run, so the redirect itself must carry an explicit edge directive: a generic sign-in
    # redirect must never be served from Fastly to another user. (Rails normalizes the
    # Cache-Control directive order to "max-age=0, private" on the wire.)
    get dashboard_path

    assert_redirected_to sign_in_path
    assert_equal "max-age=0, private", response.headers["Cache-Control"]
    assert_equal "max-age=0", response.headers["Surrogate-Control"]
  end
end
