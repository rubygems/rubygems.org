# frozen_string_literal: true

require "test_helper"

class LocaleRoutingTest < ActionDispatch::IntegrationTest
  test "non-default locale is extracted from path" do
    get "/de"

    assert_response :success
    assert_equal :de, I18n.locale
  end

  test "paths without locale use default locale" do
    get "/"

    assert_response :success
    assert_equal I18n.default_locale, I18n.locale
  end

  test "default locale path redirects to unprefixed path" do
    get "/en/pages/about"

    assert_response :redirect
    assert_redirected_to "/pages/about"
  end

  test "default locale root redirects to /" do
    get "/en"

    assert_response :redirect
    assert_redirected_to "/"
  end

  test "localized page path works" do
    get "/de/pages/about"

    assert_response :success
    assert_equal :de, I18n.locale
  end

  test "API routes are not affected by locale scope" do
    rubygem = create(:rubygem, name: "rails")
    create(:version, rubygem: rubygem, number: "7.0.0")

    get "/api/v1/gems/rails.json"

    assert_response :success
    assert_equal I18n.default_locale, I18n.locale
  end
end
