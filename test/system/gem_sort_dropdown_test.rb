# frozen_string_literal: true

require "application_system_test_case"

class GemSortDropdownTest < ApplicationSystemTestCase
  SORT_BUTTON = "button[aria-haspopup='menu']"
  MENU = "[role='menu'][aria-label='Sort gems by']"

  setup do
    @user = create(:user)
  end

  test "keyboard users open, move through, close and choose from the sort menu" do
    own_gems "alpha" => 10, "bravo" => 30
    visit profile_path(@user.handle)

    find(SORT_BUTTON).send_keys(:enter)

    assert_selector MENU
    assert_selector "#{SORT_BUTTON}[aria-expanded='true']"
    assert_focused "Number of downloads"

    press "ArrowDown"

    assert_focused "Alphabetical"

    press "ArrowDown"

    assert_focused "Most recently published"

    press "End"

    assert_focused "Alphabetical"

    press "Escape"

    assert_no_selector MENU
    assert_selector "#{SORT_BUTTON}[aria-expanded='false']:focus"

    press "ArrowUp"

    assert_focused "Alphabetical"

    press "Enter"

    assert_selector SORT_BUTTON, text: "Sort: Alphabetical"
    assert_equal %w[alpha bravo], all("h4").map(&:text)

    visit profile_path(@user.handle)

    assert_selector SORT_BUTTON, text: "Sort: Alphabetical"
  end

  test "tab moves on and closes the menu" do
    own_gems "alpha" => 10
    visit profile_path(@user.handle)

    find(SORT_BUTTON).click

    assert_selector MENU
    press "Tab"

    assert_no_selector MENU
    assert_no_selector "#{MENU} :focus", visible: :all
  end

  test "an outside click closes the menu and a choice can be clicked after reopening" do
    own_gems "alpha" => 10
    visit profile_path(@user.handle)

    find(SORT_BUTTON).click
    find("h1").click

    assert_no_selector MENU

    find(SORT_BUTTON).click
    find("#{MENU} [role='menuitemradio']", text: "Most recently published").click

    assert_selector SORT_BUTTON, text: "Sort: Most recently published"
  end

  private

  def own_gems(downloads_by_name)
    downloads_by_name.each do |name, downloads|
      create(:version, rubygem: create(:rubygem, name:, downloads:, owners: [@user]))
    end
  end

  def press(key)
    page.driver.with_playwright_page { it.keyboard.press(key) }
  end

  def assert_focused(text)
    assert_selector "#{MENU} [role='menuitemradio']:focus", text:
  end
end
