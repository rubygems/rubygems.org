require "test_helper"
require "capybara/minitest"

class AdvancedSearchTest < SystemTest
  include ESHelper

  setup do
    headless_chrome_driver

    visit advanced_search_path
  end

  test "searches for a gem while scoping advanced attributes" do
    rubygem = create(:rubygem, name: "LDAP", number: "1.0.0", downloads: 3)
    create(:version, summary: "some summary", description: "Hello World", rubygem: rubygem)

    import_and_refresh

    fill_in "Search Gems…", with: "downloads: <5"
    click_button "advanced_search_submit"

    assert current_path == search_path
    assert has_content? "LDAP"
  end

  test "enter inside any field will submit form" do
    ["#name", "#summary", "#description", "#downloads", "#updated"].each do |el|
      visit advanced_search_path
      find(el).send_keys(:return)
      assert current_path == search_path
    end
  end

  test "forms search query out of advanced attributes" do
    fill_in "name", with: "hello"
    fill_in "summary", with: "world"
    fill_in "description", with: "foo"
    fill_in "downloads", with: ">69"
    fill_in "updated", with: ">2021-05-05"

    page.find("#home_query").assert_text "name: hello summary: world description: foo downloads: >69 updated: >2021-05-05"
  end

  teardown do
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end
end
