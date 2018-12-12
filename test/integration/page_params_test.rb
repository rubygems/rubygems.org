require 'test_helper'

class PageParamsTest < SystemTest
  test "page params is not integer" do
    visit stats_path(page: "3\"")
    assert page.has_content? "Stats"
  end

  test "page param is more than 1000" do
    visit stats_path(page: "553402322211286548480")
    assert page.has_content? "Stats"
  end
end
