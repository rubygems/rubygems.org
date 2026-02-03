require "application_system_test_case"

class PagesTest < ApplicationSystemTestCase
  test "renders /pages/about for all supported languages" do
    I18n.available_locales.each do |locale|
      visit "/pages/about?locale=#{locale}"

      assert page.has_content? I18n.t("pages.about.title", locale: locale)
    end
  end

  test "renders /pages/download" do
    rubygem = create(:rubygem, name: "rubygems-update")
    create(:version, number: "1.4.8", rubygem: rubygem)
    create(:version,
      number: "3.5.22",
      created_at: Time.zone.local(2024, 10, 16),
      rubygem: rubygem)

    visit "/pages/download"

    assert page.has_content?("v3.5.22 - October 16, 2024")
  end

  test "renders /pages/data" do
    visit "/pages/data"

    assert page.has_content?("PostgreSQL Data")
  end

  test "renders /pages/security" do
    visit "/pages/security"

    assert page.has_content?("Security")
  end

  test "renders /pages/supporters" do
    visit "/pages/supporters"

    assert page.has_content?("Supporters")
  end

  test "redirects /pages/sponsors to /pages/supporters" do
    visit "/pages/sponsors"

    assert_current_path "/pages/supporters"
    assert page.has_content?("Supporters")
  end
end
