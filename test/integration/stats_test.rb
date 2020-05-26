require "test_helper"
require "capybara/minitest"

class StatsTest < SystemTest
  setup do
    headless_chrome_driver
    @rubygem = create(:rubygem, number: "0.0.1", downloads: 100)
  end

  test "downloads animation bar" do
    visit stats_path
    assert page.find(:css, ".stats__graph__gem__meter")
    assert page.has_content?(@rubygem.downloads)
  end

  teardown { Capybara.use_default_driver }
end
