# frozen_string_literal: true

require "test_helper"

class LocaleRoutingTest < ActionDispatch::IntegrationTest
  IGNORED_LOCALE_QUERIES = ["locale=de", "locale=xx", "locale="].freeze

  test "non-default locale is extracted from path" do
    get "/de"

    assert_response :success
    assert_includes response.body, %(<html lang="de")
  end

  test "paths without locale use default locale" do
    get "/"

    assert_response :success
    assert_includes response.body, %(<html lang="en")
  end

  test "query string locale is ignored" do
    get "/?locale=de"

    assert_response :success
    assert_includes response.body, %(<html lang="en")
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

    assert_response :unprocessable_content
  end

  test "locale switching does not retry actions that raise an invalid locale error" do
    controller = ApplicationController.new
    request = ActionController::TestRequest.create(ApplicationController)
    request.path_parameters = { locale: :en }
    controller.request = request
    calls = 0

    assert_raises(I18n::InvalidLocale) do
      controller.switch_locale do
        calls += 1
        raise I18n::InvalidLocale, :invalid
      end
    end
    assert_equal 1, calls
  end

  test "the localized sponsors alias redirects with the locale preserved" do
    get "/de/pages/sponsors"

    assert_redirected_to "/de/pages/supporters"
  end

  test "the localized gem transfer alias redirects with the locale preserved" do
    user = create(:user)

    get transfer_rubygems_path(locale: :de, as: user)

    assert_redirected_to organization_transfer_rubygems_path(locale: :de)
  end

  test "the localized organization onboarding alias redirects with the locale preserved" do
    user = create(:user)
    FeatureFlag.enable_for_actor(FeatureFlag::ORGANIZATIONS, user)

    get organization_onboarding_path(locale: :de, as: user)

    assert_redirected_to organization_onboarding_name_path(locale: :de)
  end

  test "the localized gem transfer alias still enforces sign-in and MFA without side effects" do
    assert_no_difference -> { RubygemTransfer.count } do
      get transfer_rubygems_path(locale: :de)
    end

    assert_redirected_to sign_in_path(locale: :de)

    user = create(:user)
    rubygem = create(:rubygem, owners: [user])
    GemDownload.increment(Rubygem::MFA_REQUIRED_THRESHOLD + 1, rubygem_id: rubygem.id)

    assert_no_difference -> { RubygemTransfer.count } do
      assert_no_enqueued_jobs do
        get transfer_rubygems_path(locale: :de, as: user)
      end
    end

    assert_redirected_to edit_settings_path(locale: :de)
  end

  test "the localized organization onboarding alias still enforces sign-in, MFA, and the feature flag without side effects" do
    user = create(:user)

    assert_no_difference -> { OrganizationOnboarding.count } do
      get organization_onboarding_path(locale: :de)

      assert_redirected_to sign_in_path(locale: :de)

      get organization_onboarding_path(locale: :de, as: user)

      assert_response :not_found

      FeatureFlag.enable_for_actor(FeatureFlag::ORGANIZATIONS, user)
      rubygem = create(:rubygem, owners: [user])
      GemDownload.increment(Rubygem::MFA_REQUIRED_THRESHOLD + 1, rubygem_id: rubygem.id)
      assert_no_enqueued_jobs do
        get organization_onboarding_path(locale: :de, as: user)
      end

      assert_redirected_to edit_settings_path(locale: :de)
    end
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

    refute_empty asset_urls
    assert_empty asset_urls.grep(%r{\A/de/})
  end

  test "navigation links are locale-aware" do
    create(:rubygem, name: "sandworm", number: "1.0.0")

    get "/de/gems"

    assert_response :success
    assert page.has_link?(href: "/de/stats")
  end

  test "positional route helpers preserve the current page locale" do
    create(:rubygem, name: "sandworm", number: "1.0.0")

    get "/gems/sandworm"

    assert_response :success
    assert page.has_link?("sandworm", href: "/gems/sandworm")

    get "/de/gems/sandworm"

    assert_response :success
    assert page.has_link?("sandworm", href: "/de/gems/sandworm")
  end

  test "an encoded external host in a default-locale path is never redirected" do
    redirected_externally =
      begin
        get "/en/%2F%2Fevil.com"
        response.redirect? && response.headers["Location"].to_s.match?(%r{\A(https?:)?//})
      rescue ActionController::RoutingError
        false
      end

    refute redirected_externally, "leaked an external/protocol-relative redirect"
  end

  test "the default locale strip ignores routing and host query keys" do
    hostile_query = "host=evil.com&protocol=javascript&controller=admin&action=destroy&only_path=false&query=rails"

    %i[get head].each do |verb|
      send(verb, "/en/search?#{hostile_query}")

      assert_response :moved_permanently
      location = URI.parse(response.headers["Location"])

      assert_includes [nil, Gemcutter::HOST, "www.example.com"], location.host, "#{verb} redirected to #{location}"
      assert_equal "/search", location.path
      assert_equal hostile_query, location.query
    end
  end

  test "a localized gem page never emits ?locale= query params" do
    create(:rubygem, name: "sandworm", number: "1.0.0")

    get "/de/gems/sandworm"

    assert_response :success
    refute_includes response.body, "?locale=", "locale leaked as a query param, fragmenting the CDN cache"
  end

  test "localized gem page renders unlocalized download urls" do
    create(:rubygem, name: "sandworm", number: "1.0.0")

    get "/de/gems/sandworm"

    assert_response :success
    assert page.has_link?(href: "/downloads/sandworm-1.0.0.gem")
    refute_includes response.body, "/de/downloads/"
  end

  test "localized dependency json renders locale-aware links" do
    version = create(:version)
    dependency = create(:rubygem, name: "nested-dependency", number: "1.0.0")
    create(:dependency, requirements: ">= 0", scope: :runtime, version:, rubygem: dependency)

    get "/de/gems/#{version.rubygem.slug}/versions/#{version.number}/dependencies.json"

    assert_response :success
    html = Nokogiri::HTML.fragment(response.parsed_body["run_html"])

    assert_equal ["/de/gems/nested-dependency/versions/1.0.0"], html.css("a").pluck("href")
    assert_equal(["/de/gems/nested-dependency/versions/1.0.0/dependencies.json"], html.css(".deps_expanded-link").pluck("data-url"))
  end

  test "query-string locales never leak into pagination links" do
    31.times { |i| create(:rubygem, name: "aardvark#{i}", number: "1.0.0") }
    expected = {
      "/gems" => "/gems?page=2",
      "/gems?locale=xx" => "/gems?page=2",
      "/gems?locale=fr" => "/gems?page=2",
      "/gems?locale[]=fr" => "/gems?page=2",
      "/de/gems?locale=xx" => "/de/gems?page=2",
      "/fr/gems?locale=de" => "/fr/gems?page=2"
    }

    expected.each do |path, next_page|
      get path

      assert_response :success
      assert page.has_link?(href: next_page), "#{path} should link to #{next_page}"
      assert_empty page.all(:css, "a[href*='page=2']").map { it[:href] }.grep(%r{\A/(?!de/|fr/)[a-z]{2}(-[A-Z]{2})?/gems}),
        "#{path} leaked a query locale into a path prefix"
      assert_includes response.headers["Cache-Control"], "public"
    end

    get "/gems?locale=xx"
    get page.first(:link, href: "/gems?page=2")[:href]

    assert_response :success
    assert_includes response.body, %(<html lang="en")
  end

  test "an ignored query locale does not change the default search engine tags" do
    %w[/ /de].each do |path|
      get path
      clean_tags = search_engine_link_hrefs

      refute_empty clean_tags

      IGNORED_LOCALE_QUERIES.each do |query|
        get "#{path}?#{query}"

        assert_equal clean_tags, search_engine_link_hrefs, "#{path}?#{query} changed the search engine tags"
        assert clean_tags.values.none? { it.include?("?") }, "tag urls must not carry query strings"
      end
    end
  end

  test "meaningful query parameters suppress the automatic search engine tags" do
    ["/gems?page=2", "/gems?letter=B", "/search?query=rails", "/?utm_source=test", "/gems?page=2&locale=de"].each do |path|
      get path

      assert_equal 0, search_engine_link_count, "#{path} should not emit automatic canonical/hreflang tags"
    end
  end

  test "localized and default variants of a page share the same hreflang cluster" do
    get "/pages/about"
    english_cluster = search_engine_link_hrefs.except("canonical")

    get "/de/pages/about"

    assert_equal english_cluster, search_engine_link_hrefs.except("canonical")
    assert_equal "http://localhost/de/pages/about", search_engine_link_hrefs["canonical"]
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

  test "the header language switcher is rendered" do
    get "/"

    assert_response :success
    assert page.has_css?(%(button[aria-label="#{I18n.t('layouts.application.header.language')}"]))
    language_menu = %(nav[aria-label="#{I18n.t('layouts.application.header.language')}"])

    assert page.has_css?("#{language_menu} a[href='/de']", text: I18n.t(:locale_name, locale: :de), visible: false)
    refute page.has_css?(%(footer nav[aria-label="Languages"]))
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

    assert_response :unprocessable_content
    de_href = page.first(:link, I18n.t(:locale_name, locale: :de))[:href]

    assert_equal 0, search_engine_link_count, "a failed form submission must not emit canonical/hreflang tags"

    get de_href

    assert_response :success
  end

  test "a region locale (zh-CN) is taken from the URL path" do
    get "/zh-CN"

    assert_response :success
    assert_includes response.body, %(<html lang="zh-CN")
  end

  test "positional route helper arguments target non-locale segments" do
    rubygem = create(:rubygem, name: "rails")

    assert_equal "/gems/rails", rubygem_path(rubygem.slug)
    assert_equal "/gems/rails/versions/7.0.0", rubygem_version_path(rubygem.slug, "7.0.0")
  end

  test "admin routes are not affected by locale scope" do
    assert_raises(ActionController::RoutingError) do
      get "/de/admin"
    end
  end

  private

  def search_engine_link_hrefs
    html = response.parsed_body
    tags = html.css('link[rel="alternate"][hreflang]').to_h { [it["hreflang"], it["href"]] }
    canonical = html.at_css('link[rel="canonical"]')
    canonical ? tags.merge("canonical" => canonical["href"]) : tags
  end
end
