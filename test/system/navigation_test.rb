# frozen_string_literal: true

require "application_system_test_case"

class NavigationTest < ApplicationSystemTestCase
  test "closing the mobile menu with escape updates its expanded state" do
    page.current_window.resize_to(393, 852)
    visit root_path

    menu_button = find("button[aria-label='Open menu']")

    assert_selector "button[aria-label='Open menu'][aria-expanded='false']"

    menu_button.click

    assert_selector "dialog[open]"
    assert_selector "button[aria-label='Open menu'][aria-expanded='true']"

    find("body").send_keys(:escape)

    assert_no_selector "dialog[open]"
    assert_selector "button[aria-label='Open menu'][aria-expanded='false']"
  end
end
