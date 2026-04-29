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

  test "default locale root redirects to unprefixed root" do
    get "/en?query=rails"

    assert_response :redirect
    assert_redirected_to "/?query=rails"
  end

  test "localized redirects preserve locale path" do
    get "/de/gems/transfer"

    assert_response :redirect
    assert_redirected_to "/de/gems/transfer/organization"

    get "/de/organizations/onboarding"

    assert_response :redirect
    assert_redirected_to "/de/organizations/onboarding/name"

    get "/de/pages/sponsors"

    assert_response :redirect
    assert_redirected_to "/de/pages/supporters"
  end

  test "localized page path works" do
    get "/de/pages/about"

    assert_response :success
    assert page.has_link?(I18n.t("layouts.application.footer.security", locale: :de), href: "/de/pages/security")
  end

  test "positional route helper arguments still target non-locale segments" do
    rubygem = create(:rubygem, name: "rails")

    assert_equal "/gems/rails", rubygem_path(rubygem.slug)
    assert_equal "/gems/rails/versions/7.0.0", rubygem_version_path(rubygem.slug, "7.0.0")
  end

  test "admin routes are not affected by locale scope" do
    assert_raises(ActionController::RoutingError) do
      get "/de/admin"
    end
  end
end
