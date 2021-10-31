require "test_helper"
require "capybara/minitest"

class AdvancedSearchTest < SystemTest
  include ESHelper

  setup do
    headless_chrome_driver

    visit advanced_search_path
  end

  test "enter inside any field will submit form" do
    ["#name", "#summary", "#description", "#downloads", "#updated"].each do |el|
      visit advanced_search_path
      find(el).send_keys(:return)
      assert current_path == search_path
    end
  end

  teardown do
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end
end
