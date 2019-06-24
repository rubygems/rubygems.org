require "test_helper"

class AboutPageTest < ActionDispatch::IntegrationTest
  def assert_about_page_i18n(local)
    get page_url("about"), params: { locale: local }

    assert_response :success
    assert page.has_content? I18n.t("pages.about.title")
  end

  test "about page i18n for all supported languages" do
    I18n.available_locales.each do |locale|
      assert_about_page_i18n locale
    end
  end
end
