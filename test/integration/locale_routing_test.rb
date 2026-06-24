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

  test "the localized sponsors alias redirects with the locale preserved" do
    get "/de/pages/sponsors"

    assert_redirected_to "/de/pages/supporters"
  end

  test "localized page path works" do
    get "/de/pages/about"

    assert_response :success
    assert page.has_link?(I18n.t("layouts.application.footer.security", locale: :de), href: "/de/pages/security")
  end

  test "the active nav link is locale-aware" do
    create(:rubygem, name: "sandworm", number: "1.0.0")

    get "/de/gems"

    assert_response :success
    assert page.has_css?("a.header__nav-link.is-active", text: "Gems")
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
