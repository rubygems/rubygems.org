# frozen_string_literal: true

require "test_helper"

class LocaleRoutingTest < ActionDispatch::IntegrationTest
  test "non-default locale is extracted from path" do
    get "/de"

    assert_response :success
    assert_includes response.body, "RubyGems.org ist der Gem-Hosting-Dienst"
  end

  test "paths without locale use default locale" do
    get "/"

    assert_response :success
    assert_includes response.body, "RubyGems.org is the Ruby community"
  end

  test "query string locale is ignored" do
    get "/?locale=de"

    assert_response :success
    assert_includes response.body, "RubyGems.org is the Ruby community"
  end

  test "invalid locale path does not match localized routes" do
    assert_raises(ActionController::RoutingError) do
      get "/xx/gems/rails"
    end
  end

  test "API routes are not affected by locale scope" do
    assert_raises(ActionController::RoutingError) do
      get "/de/api/v1/gems/rails.json"
    end
  end

  test "default locale path redirects to unprefixed path" do
    get "/en/pages/about"

    assert_response :redirect
    assert_redirected_to "/pages/about"
  end

  test "default locale redirect preserves query string" do
    get "/en/search?query=rails"

    assert_response :redirect
    assert_redirected_to "/search?query=rails"
  end

  test "default locale redirect preserves dotted path segments" do
    get "/en/gems/rails/versions/7.0.0?query=release"

    assert_response :redirect
    assert_redirected_to "/gems/rails/versions/7.0.0?query=release"
  end

  test "default locale root redirects to unprefixed root" do
    get "/en?query=rails"

    assert_response :redirect
    assert_redirected_to "/?query=rails"
  end

  test "default locale strip only redirects safe request methods" do
    post "/en/users", params: { user: { handle: "", email: "", password: "" } }

    assert_response :success
  end

  test "the localized sponsors alias redirects with the locale preserved" do
    get "/de/pages/sponsors"

    assert_redirected_to "/de/pages/supporters"
  end

  test "localized page path works" do
    get "/de/pages/about"

    assert_response :success
    assert page.has_link?(I18n.t("layouts.application.footer.security", locale: :de), href: "/de/pages/security")
  end

  test "localized pages use root-relative asset urls" do
    get "/de/pages/about"

    assert_response :success
    asset_urls = page.all(:css, %(link[rel="stylesheet"][href], script[src]), visible: false).filter_map { |node| node[:href] || node[:src] }

    assert_not_empty asset_urls
    assert_empty asset_urls.grep(%r{\A/de/})
  end

  test "the active nav link is locale-aware" do
    create(:rubygem, name: "sandworm", number: "1.0.0")

    get "/de/gems"

    assert_response :success
    assert page.has_css?("a.header__nav-link.is-active", text: "Gems")
  end

  test "the default locale strip can never produce an external redirect" do
    redirected_externally =
      begin
        get "/en/%2F%2Fevil.com"
        response.redirect? && response.headers["Location"].to_s.match?(%r{\A(https?:)?//})
      rescue ActionController::RoutingError
        false
      end

    refute redirected_externally, "leaked an external/protocol-relative redirect"
  end

  test "a localized gem page never emits ?locale= query params" do
    create(:rubygem, name: "sandworm", number: "1.0.0")

    get "/de/gems/sandworm"

    assert_response :success
    refute_includes response.body, "?locale=", "locale leaked as a query param, fragmenting the CDN cache"
  end

  test "localized gem page keeps API helper urls unlocalized" do
    create(:rubygem, name: "sandworm", number: "1.0.0")

    get "/de/gems/sandworm"

    assert_response :success
    assert page.has_css?(%(.gem__downloads-wrap[data-href="/api/v1/downloads/sandworm-1.0.0.json"]))
  end

  test "localized pages emit a self-referential canonical plus hreflang alternates" do
    get "/de"

    assert_response :success
    assert page.has_css?(%(link[rel="canonical"][href="http://localhost/de"]), visible: false)
    alternates = page.all(:css, %(link[rel="alternate"][hreflang]), visible: false)

    assert_equal I18n.available_locales.length + 1, alternates.length
    assert page.has_css?(%(link[rel="alternate"][hreflang="x-default"][href="http://localhost/"]), visible: false)
  end

  test "search engine tags are omitted for signed-in requests" do
    user = create(:user, remember_token_expires_at: Gemcutter::REMEMBER_FOR.from_now)
    post session_path(session: { who: user.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })

    get "/de"

    assert_response :success
    refute page.has_css?(%(link[rel="canonical"]), visible: false)
    refute page.has_css?(%(link[rel="alternate"][hreflang]), visible: false)
  end

  test "the footer language switcher is rendered" do
    get "/"

    assert_response :success
    assert page.has_link?(I18n.t(:locale_name, locale: :de), href: "/de")
  end

  test "the language switcher keeps the current path when changing locale" do
    create(:rubygem, name: "sandworm", number: "1.0.0")

    get "/gems/sandworm"

    assert_response :success
    assert page.has_link?(I18n.t(:locale_name, locale: :de), href: "/de/gems/sandworm")
  end

  test "the language switcher preserves query parameters (minus a stale locale)" do
    get "/search?query=rails&locale=fr"

    assert_response :success
    assert page.has_link?(I18n.t(:locale_name, locale: :de), href: "/de/search?query=rails")
  end

  test "the language switcher targets a GET page after a failed form submission" do
    post users_path, params: { user: { handle: "", email: "", password: "" } }

    assert_response :success
    de_href = page.find_link(I18n.t(:locale_name, locale: :de))[:href]

    get de_href

    assert_response :success
  end

  test "a region locale (zh-CN) is taken from the URL path" do
    get "/zh-CN"

    assert_response :success
    assert_includes response.body, %(<html lang="zh-CN")
  end

  test "keyword route helper arguments target non-locale segments" do
    rubygem = create(:rubygem, name: "rails")

    assert_equal "/gems/rails", rubygem_path(id: rubygem.slug)
    assert_equal "/gems/rails/versions/7.0.0", rubygem_version_path(rubygem_id: rubygem.slug, id: "7.0.0")
  end

  test "admin routes are not affected by locale scope" do
    assert_raises(ActionController::RoutingError) do
      get "/de/admin"
    end
  end
end
