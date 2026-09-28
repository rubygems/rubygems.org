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

    language_button = find(%(button[aria-label="#{I18n.t('layouts.application.header.language')}"]))

    assert_equal "false", language_button["aria-expanded"]

    language_button.click

    assert_equal "true", language_button["aria-expanded"]

    language_button.click

    assert_equal "false", language_button["aria-expanded"]

    language_button.click
    click_link "Deutsch"

    assert_equal "de", page.find("html")[:lang]
  end

  test "mobile language options open from the navigation menu" do
    use_device_profile :mobile
    visit root_path

    assert_no_selector %(button[aria-label="#{I18n.t('layouts.application.header.language')}"])

    find(%(button[aria-label="#{I18n.t('layouts.application.header.open_menu')}"])).click

    within "dialog[open]" do
      assert_no_link "Deutsch"

      language_row = find("button[aria-controls='mobile-language-panel']", text: "English")

      assert_equal "false", language_row["aria-expanded"]

      language_row.click

      assert_selector "#mobile-language-heading", text: "Language"
      assert_selector "a[aria-current='true']", text: "English"
      assert_no_link href: "https://blog.rubygems.org"

      find(%(button[aria-label="#{I18n.t('layouts.application.header.back')}"])).click

      assert_link href: "https://blog.rubygems.org"
      assert_no_link "Deutsch"

      language_row.click
      click_link "Deutsch"
    end

    assert_equal "de", page.find("html")[:lang]

    find("button[data-dialog-target='button']").click

    within "dialog[open]" do
      assert_selector "button[aria-controls='mobile-language-panel']", text: "Deutsch"
    end
  end

  test "localized root keeps the home page layout" do
    visit "/de"

    assert_selector "input#homepage_gem_query"
    assert_text I18n.t("home.index.learn.install_rubygems", locale: :de)
    assert_no_selector "nav[aria-label='Breadcrumb']"
  end

  test "positional route helper arguments target non-locale segments" do
    assert_equal "/gems/rails", rubygem_path("rails")
    assert_equal "/gems/rails/versions/7.0.0", rubygem_version_path("rails", "7.0.0")
  end
end
