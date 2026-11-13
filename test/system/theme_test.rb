# frozen_string_literal: true

require "application_system_test_case"

class ThemeTest < ApplicationSystemTestCase
  test "cycles auto, light, dark and keeps the choice across page loads" do
    visit root_path

    assert_selector "html[data-theme='auto']"

    find("[data-testid='theme-toggle']").click

    assert_selector "html[data-theme='light']"

    find("[data-testid='theme-toggle']").click

    assert_selector "html[data-theme='dark']"

    visit root_path

    assert_selector "html[data-theme='dark']"

    find("[data-testid='theme-toggle']").click

    assert_selector "html[data-theme='auto']"
  end
end
