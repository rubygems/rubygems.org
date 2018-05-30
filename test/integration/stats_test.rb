require 'test_helper'

class StatsTest < SystemTest
  test "page params is not integer" do
    string_param_path = '/stats?page="3\""'
    visit URI.encode(string_param_path)
    assert page.has_content? "Stats"
  end
end
