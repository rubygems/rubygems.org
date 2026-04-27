# frozen_string_literal: true

require "application_system_test_case"

class LocaleTest < ApplicationSystemTestCase
  test "html lang attribute is set from locale" do
    I18n.available_locales.each do |locale|
      visit locale == I18n.default_locale ? root_path : "/#{locale}"

      assert_equal locale.to_s, page.find("html")[:lang]
    end
  end

  test "links generated during a localized request keep the locale prefix" do
    visit "/de/pages/about"

    assert_equal "de", page.find("html")[:lang]
    assert page.has_link?(I18n.t("layouts.application.footer.about", locale: :de), href: "/de/pages/about")
    assert page.has_link?(I18n.t("layouts.application.footer.security", locale: :de), href: "/de/pages/security")
  end

  test "locale is switched via locale menu" do
    visit root_path

    assert_equal I18n.default_locale.to_s, page.find("html")[:lang]

    click_link "Deutsch"

    assert_equal "de", page.find("html")[:lang]
    assert_current_path "/de"
  end

  test "locale menu preserves query params except stale locale params" do
    visit "/search?query=rails&locale=fr"

    click_link "Deutsch"

    assert_equal "de", page.find("html")[:lang]
    assert_current_path "/de/search?query=rails"
  end
end
