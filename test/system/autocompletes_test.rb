# frozen_string_literal: true

require "application_system_test_case"

class AutocompletesTest < ApplicationSystemTestCase
  include SearchKickHelper

  setup do
    rubygem = create(:rubygem, name: "rubocop")
    create(:version, :reindex, rubygem: rubygem, indexed: true)
    rubygem = create(:rubygem, name: "rubocop-performance")
    create(:version, :reindex, rubygem: rubygem, indexed: true)

    visit root_path
    @fill_field = find_by_id "homepage_gem_query"
    @form = @fill_field.ancestor("form")
    @fill_field.set "rubo"
    # Wait for the autocomplete request to populate the listbox before each test.
    @form.assert_selector "[role='option']", minimum: 1
  end

  test "submitting the field runs a search" do
    @fill_field.set "rubocop"
    click_on class: "home__search__icon"

    assert_text "Search"
    assert_text "rubocop"
  end

  test "selected field is only one with cursor selecting" do
    find(".suggest-list").all("li").each(&:hover) # rubocop:disable Rails/FindEach

    assert_selector ".selected", count: 1
  end

  test "selected field is only one with arrow key selecting" do
    @fill_field.send_keys :down
    find ".selected"
    @fill_field.send_keys :down

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
    @fill_field.send_keys :down

    assert page.has_no_field? "query", with: "rubo"
  end

  test "up arrow key to choose suggestion" do
    @fill_field.send_keys :up

    assert page.has_no_field? "query", with: "rubo"
  end

  test "down arrow key should loop" do
    @fill_field.send_keys :down, :down, :down, :down

    assert_selector ".suggest-list .menu-item:last-child.selected"
  end

  test "up arrow key should loop" do
    @fill_field.send_keys :up, :up, :up, :up

    assert_selector ".suggest-list .menu-item:first-child.selected"
  end

  test "mouse hover a suggest item to choose suggestion" do
    first("li", text: "rubocop").hover

    assert_selector ".selected"
  end

  test "mouse click a suggestion item to submit" do
    first("li", text: "rubocop").click
    @form.click_button

    assert_current_path search_path, ignore_query: true
    assert_text "rubocop"
  end

  test "only one suggestion is selected when hovering" do
    suggestion_options.each(&:hover)

    assert_single_active_suggestion
  end

  test "only one suggestion is selected when using arrow keys" do
    @fill_field.send_keys :down
    @form.assert_selector "#{SUGGESTIONS}[aria-activedescendant]"
    @fill_field.send_keys :down

    assert_single_active_suggestion
  end

  test "suggestions don't appear when the gem does not exist" do
    @fill_field.set "ruxyz"

    @form.assert_no_selector "[role='option']"
  end

  test "suggestions don't appear unless the search field is focused" do
    find("h1").click

    @form.assert_no_selector "[role='option']"
  end

  test "down arrow key fills the field with a suggestion" do
    @fill_field.send_keys :down

    assert_no_field "homepage_gem_query", with: "rubo"
  end

  test "up arrow key fills the field with a suggestion" do
    @fill_field.send_keys :up

    assert_no_field "homepage_gem_query", with: "rubo"
  end

  test "down arrow key should loop" do
    @fill_field.send_keys :down, :down, :down, :down
    @form.assert_selector "#{SUGGESTIONS}[aria-activedescendant]"

    assert_equal suggestion_options.last["id"], active_descendant
  end

  test "up arrow key should loop" do
    @fill_field.send_keys :up, :up, :up, :up
    @form.assert_selector "#{SUGGESTIONS}[aria-activedescendant]"

    assert_equal suggestion_options.first["id"], active_descendant
  end

  test "hovering a suggestion selects it" do
    @form.first("[role='option']", text: "rubocop").hover

    @form.assert_selector "#{SUGGESTIONS}[aria-activedescendant]"
  end

  test "clicking a suggestion submits the search" do
    @form.first("[role='option']", text: "rubocop").click

    assert_current_path search_path, ignore_query: true
    assert_text "rubocop"
  end

  private

  SUGGESTIONS = "[data-autocomplete-target='suggestions']"

  def suggestions_list
    @form.find(SUGGESTIONS)
  end

  def suggestion_options
    suggestions_list.all("[role='option']", minimum: 0)
  end

  def active_descendant
    suggestions_list["aria-activedescendant"]
  end

  def assert_single_active_suggestion
    @form.assert_selector "#{SUGGESTIONS}[aria-activedescendant]"

    assert_equal(1, suggestion_options.count { |option| option["id"] == active_descendant })
  end
end
