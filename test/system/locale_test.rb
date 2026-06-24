# frozen_string_literal: true

require "application_system_test_case"

class LocaleTest < ApplicationSystemTestCase
  test "html lang attribute is set from locale" do
    I18n.available_locales.each do |locale|
      visit "/#{locale}"

      assert_equal locale.to_s, page.find("html")[:lang]
    end
  end

  test "locale is switched via locale menu" do
    skip "locale switcher temporarily disabled"

    visit root_path

    assert_equal I18n.default_locale.to_s, page.find("html")[:lang]

    click_link "Deutsch"

    assert_equal "de", page.find("html")[:lang]
  end

  test "localized root keeps the home page layout" do
    visit "/de"

    assert_selector "body.body--index"
    assert_no_selector "header.header--interior"
    assert_no_selector "main.main--interior"
  end

  test "keyword route helper arguments target non-locale segments" do
    assert_equal "/gems/rails", rubygem_path(id: "rails")
    assert_equal "/gems/rails/versions/7.0.0", rubygem_version_path(rubygem_id: "rails", id: "7.0.0")
  end
end
