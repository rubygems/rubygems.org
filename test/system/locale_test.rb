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
    visit root_path

    assert_equal I18n.default_locale.to_s, page.find("html")[:lang]

    click_link "Deutsch"

    assert_equal "de", page.find("html")[:lang]
    assert_current_path "/de"
  end

  test "localized root keeps the home page layout" do
    visit "/de"

    assert_selector "body.body--index"
    assert_no_selector "header.header--interior"
    assert_no_selector "main.main--interior"
  end

  test "locale menu preserves query params except stale locale params" do
    visit "/search?query=rails&locale=fr"

    click_link "Deutsch"

    assert_equal "de", page.find("html")[:lang]
    assert_current_path "/de/search?query=rails"
  end

  test "locale menu does not let query params replace path params" do
    create(:rubygem, name: "rails")

    visit "/gems/rails?id=other"

    click_link "Deutsch"

    assert_equal "de", page.find("html")[:lang]
    assert_current_path "/de/gems/rails?id=other"
  end

  test "locale menu uses the form page after failed form submissions" do
    visit sign_up_path

    fill_in "Email", with: "email@person.com"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign up"

    assert_text "errors prohibited"

    click_link "Deutsch"

    assert_equal "de", page.find("html")[:lang]
    assert_current_path "/de/users/new"
  end

  test "positional route helper arguments still target non-locale segments" do
    assert_equal "/gems/rails", rubygem_path("rails")
    assert_equal "/gems/rails/versions/7.0.0", rubygem_version_path("rails", "7.0.0")
  end
end
