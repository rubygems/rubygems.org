# frozen_string_literal: true

require "application_system_test_case"

class LocaleTest < ApplicationSystemTestCase
  test "html lang attribute is set from locale" do
    skip "locales temporarily disabled"
    I18n.available_locales.each do |locale|
      visit root_path(locale: locale)

      assert_equal locale.to_s, page.find("html")[:lang]
    end
  end

  test "locale is switched via locale menu" do
    skip "locales temporarily disabled"

    visit root_path

    assert_equal I18n.default_locale.to_s, page.find("html")[:lang]

    click_link "Deutsch"

    assert_equal "de", page.find("html")[:lang]
  end
end
