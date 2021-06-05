require "test_helper"
require "capybara/minitest"

class AutocompletesTest < SystemTest
  include ESHelper

  setup do
    headless_chrome_driver

    rubygem = create(:rubygem, name: "rubocop")
    create(:version, rubygem: rubygem, indexed: true)
    rubygem = create(:rubygem, name: "rubocop-performance")
    create(:version, rubygem: rubygem, indexed: true)
    import_and_refresh

    visit root_path
    @fill_field = find_by_id "home_query"
    @fill_field.set "rubo"
    wait_for_ajax
  end

  def wait_for_ajax
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop do
        active = page.evaluate_script("jQuery.active")
        break if active.zero?
      end
    end
  end

  test "search field" do
    @fill_field.set "rubocop"
    click_on class: "home__search__icon"
    assert page.has_content? "search"
    assert page.has_content? "rubocop"
  end

  test "selected field is only one with cursor selecting" do
    find(".suggest-list").all("li").each(&:hover)
    assert_selector ".selected", count: 1
  end

  test "selected field is only one with arrow key selecting" do
    @fill_field.native.send_keys :down
    find ".selected"
    @fill_field.native.send_keys :down
    assert_selector ".selected", count: 1
  end

  test "suggest list doesn't appear with gem not existing" do
    @fill_field.set "ruxyz"
    assert_selector ".menu-item", count: 0
  end

  test "suggest list doesn't appear unless the search field is focused" do
    find("h1").click
    assert_selector ".menu-item", count: 0
  end

  test "down arrow key to choose suggestion" do
    @fill_field.native.send_keys :down
    assert page.has_no_field? "home_query", with: "rubo"
  end

  test "up arrow key to choose suggestion" do
    @fill_field.native.send_keys :up
    assert page.has_no_field? "home_query", with: "rubo"
  end

  test "down arrow key should loop" do
    @fill_field.native.send_keys :down, :down, :down, :down
    assert find("#suggest-home").all(".menu-item").last.matches_css?(".selected")
  end

  test "up arrow key should loop" do
    @fill_field.native.send_keys :up, :up, :up, :up
    assert find("#suggest-home").all(".menu-item").first.matches_css?(".selected")
  end

  test "mouse hover a suggest item to choose suggestion" do
    find("li", text: "rubocop", match: :first).hover
    assert_selector ".selected"
  end

  test "mouse click a suggestion item to submit" do
    find("li", text: "rubocop", match: :first).click
    assert_equal current_path, search_path || "/gems/"
    assert page.has_content? "rubocop"
  end

  teardown do
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end
end
