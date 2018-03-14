require 'test_helper'

class StatsTest < SystemTest
  test "page params is not integer" do
    visit '/stats?page=wefi253%20'
    assert page.has_content? "Stats"
  end
end
