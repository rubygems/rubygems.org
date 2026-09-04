# frozen_string_literal: true

require "application_system_test_case"

class NavigationTest < ApplicationSystemTestCase
  test "slash focuses the header search" do
    visit stats_path

    find("body").send_keys("/")

    assert_selector "#query:focus"
  end

  test "slash reveals and focuses the header search on mobile" do
    page.current_window.resize_to(393, 852)
    visit stats_path

    assert_no_selector "[data-reveal-search-target='item']", visible: true

    find("body").send_keys("/")

    assert_selector "[data-reveal-search-target='item']", visible: true
    assert_selector "#query:focus"
    assert_no_selector "dialog[open]"
    assert_selector "button[aria-label='Open menu'][aria-expanded='false']"
  end

  test "slash remains available in editable elements" do
    visit stats_path
    page.execute_script <<~JAVASCRIPT
      document.querySelector("main").insertAdjacentHTML(
        "afterbegin",
        '<textarea aria-label="Test editor"></textarea><div contenteditable="true" role="textbox" aria-label="Test content editor"></div>',
      )
    JAVASCRIPT

    editor = find("textarea[aria-label='Test editor']")
    editor.send_keys("/")

    assert_field "Test editor", with: "/"
    assert_no_selector "#query:focus"

    content_editor = find("[aria-label='Test content editor']")
    content_editor.send_keys("/")

    assert_equal "/", content_editor.text
    assert_no_selector "#query:focus"
  end

  test "modified slash does not focus the header search" do
    visit stats_path

    page.driver.with_playwright_page do |playwright_page|
      playwright_page.keyboard.press("Control+/")
    end

    assert_no_selector "#query:focus"
  end

  test "tabbing on mobile leaves the navigation menu closed" do
    page.current_window.resize_to(393, 852)
    visit stats_path

    find("body").send_keys(:tab)

    assert_selector "button[aria-label='Open menu']:focus"
    assert_no_selector "dialog[open]"
    assert_selector "button[aria-label='Open menu'][aria-expanded='false']"
  end

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
