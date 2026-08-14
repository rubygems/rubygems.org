# frozen_string_literal: true

require "application_system_test_case"

class PagesTest < ApplicationSystemTestCase
  test "renders /pages" do
    visit "/pages"

    assert_text("Pages")
    assert_link("Security Engineers in Residence: FAQ", href: "/pages/security-engineers-in-residence-faq")
  end

  test "renders /pages/about for all supported languages" do
    skip "locales temporarily disabled"

    I18n.available_locales.each do |locale|
      visit "/pages/about?locale=#{locale}"

      assert_text I18n.t("pages.about.title", locale: locale)
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

    assert_text("v3.5.22 - October 16, 2024")
  end

  test "renders /pages/data" do
    visit "/pages/data"

    assert_text("PostgreSQL Data")
  end

  test "renders /pages/security" do
    visit "/pages/security"

    assert_text("Security")
    assert_text("gem-security@rubygems.org")
    assert_text("159558E35BCCF820A48DDB7CD170F9A9E4FB3D7A")
    assert_link(href: "/pages/security-engineers-in-residence-faq#our-public-key")
  end

  test "renders /pages/security-engineers-in-residence-faq" do
    visit "/pages/security-engineers-in-residence-faq"

    assert_selector "nav[aria-label='Breadcrumb'] a[href='/pages']", text: "Pages"
    assert_text("Security Engineers in Residence: FAQ")
    assert_text("gem-security@rubygems.org")
    # anchor target for the public key link on /pages/security
    assert_selector "h2#our-public-key"
  end

  test "renders /pages/supporters" do
    visit "/pages/supporters"

    assert_text("Supporters")
  end

  test "redirects /pages/sponsors to /pages/supporters" do
    visit "/pages/sponsors"

    assert_current_path "/pages/supporters"
    assert_text("Supporters")
  end
end
