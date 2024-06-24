require "test_helper"

class PagesTest < SystemTest
  test "renders existing page" do
    visit "/"
    click_link "About"

    assert page.has_content? "Welcome to RubyGems.org"
  end

  test "gracefully fails on unknown page" do
    assert_raises(ActionController::RoutingError) do
      visit "/pages/not-existing-one"
    end

    assert_raises(ActionController::RoutingError) do
      visit "/pages/data.zip"
    end
  end
end
