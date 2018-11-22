require 'test_helper'

class StatsTest < SystemTest
  test "page params is not integer" do
    visit stats_path(page: "3\"")
    assert page.has_content? "Stats"
  end
end
