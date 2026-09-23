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
    assert_selector "#homepage_gem_query.autocomplete-done"
    @form.assert_selector "[role='option']", count: 2
  end

  test "submitting the field runs a search" do
    @fill_field.set "rubocop"
    @form.click_button

    assert_current_path search_path, ignore_query: true
    assert_text "rubocop"
  end

  test "suggestions use the combobox focus model" do
    assert_equal "combobox", @fill_field["role"]
    assert_equal "homepage_gem_query_suggestions", @fill_field["aria-controls"]
    assert_equal "true", @fill_field["aria-expanded"]
    assert_equal "list", @fill_field["aria-autocomplete"]
    assert_nil suggestions_list["tabindex"]

    @fill_field.send_keys :down

    option = suggestion_options.first

    assert_equal option["id"], @fill_field["aria-activedescendant"]
    assert_equal "true", option["aria-selected"]
    assert_selector "#homepage_gem_query:focus"
  end

  test "only one suggestion is selected when hovering" do
    suggestion_options.each(&:hover)

    assert_single_active_suggestion
  end

  test "only one suggestion is selected when using arrow keys" do
    @fill_field.send_keys :down
    @form.assert_selector "[data-autocomplete-target='query'][aria-activedescendant]"
    @fill_field.send_keys :down

    assert_single_active_suggestion
  end

  test "suggestions don't appear when the gem does not exist" do
    @fill_field.set "ruxyz"

    assert @form.has_no_selector?("[role='option']")
    assert_equal "false", @fill_field["aria-expanded"]
    assert_nil @fill_field["aria-activedescendant"]
  end

  test "suggestions don't appear unless the search field is focused" do
    find("h1").click

    assert @form.has_no_selector?("[role='option']")
  end

  test "escape dismisses suggestions" do
    @fill_field.send_keys :escape

    assert @form.has_no_selector?("[role='option']")
    assert_equal "false", @fill_field["aria-expanded"]
  end

  test "leaving the search field dismisses suggestions" do
    @fill_field.send_keys :tab

    assert @form.has_no_selector?("[role='option']")
    assert_equal "false", @fill_field["aria-expanded"]
  end

  test "a delayed response does not reopen dismissed suggestions" do
    visit root_path
    delay_responses_for_shorter_terms
    @fill_field = find_by_id "homepage_gem_query"
    @form = @fill_field.ancestor("form")

    @fill_field.set "rub"

    assert_selector "#homepage_gem_query.autocomplete-loading"
    find("h1").click

    assert_selector "body[data-stale-responses]"
    settle_pending_renders

    assert @form.has_no_selector?("[role='option']")
    assert_equal "false", @fill_field["aria-expanded"]
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
    @form.assert_selector "[data-autocomplete-target='query'][aria-activedescendant]"

    assert_equal suggestion_options.last["id"], active_descendant
  end

  test "up arrow key should loop" do
    @fill_field.send_keys :up, :up, :up, :up
    @form.assert_selector "[data-autocomplete-target='query'][aria-activedescendant]"

    assert_equal suggestion_options.first["id"], active_descendant
  end

  test "hovering a suggestion selects it" do
    option = @form.first("[role='option']", text: "rubocop")
    option.hover

    @form.assert_selector "[data-autocomplete-target='query'][aria-activedescendant]"

    assert_equal option["id"], active_descendant
  end

  test "a slow response for an earlier term does not replace the suggestions" do
    # Reload so the fetch stub is in place before the first suggestion request.
    visit root_path
    delay_responses_for_shorter_terms
    @fill_field = find_by_id "homepage_gem_query"
    @form = @fill_field.ancestor("form")
    @fill_field.set "rubo"
    @form.assert_selector "[role='option']", count: 2

    @fill_field.send_keys :down
    @form.assert_selector "[data-autocomplete-target='query'][aria-activedescendant='suggest-0']"

    assert_selector "body[data-stale-responses]"
    settle_pending_renders

    assert_equal "suggest-0", active_descendant
  end

  test "clicking a suggestion submits the search" do
    @form.first("[role='option']", text: "rubocop").click

    assert_current_path search_path, ignore_query: true
    assert_text "rubocop"
  end

  test "holding the pointer down on a suggestion still submits the search" do
    page.driver.with_playwright_page do |playwright_page|
      option = playwright_page.get_by_role("option", name: "rubocop", exact: true)
      box = option.bounding_box
      playwright_page.mouse.move(box.fetch("x") + 1, box.fetch("y") + 1)
      playwright_page.mouse.down
      sleep 0.1
      playwright_page.mouse.up
    end

    assert_current_path search_path, ignore_query: true
    assert_field "query", with: "rubocop"
  end

  test "opening a prefilled search on a narrow layout loads suggestions" do
    page.current_window.resize_to(393, 852)
    visit search_path(query: "rubo")

    find("button[aria-label='Open search']").click

    assert_selector "#query.autocomplete-done"
    assert_selector "#query_suggestions [role='option']", count: 2
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
    @fill_field["aria-activedescendant"]
  end

  def assert_single_active_suggestion
    @form.assert_selector "[data-autocomplete-target='query'][aria-activedescendant]"

    assert_equal(1, suggestion_options.count { |option| option["id"] == active_descendant })
  end

  # Delays the autocomplete responses for the prefixes typed before the full
  # term, so they always resolve after the response for the full term.
  def delay_responses_for_shorter_terms
    page.execute_script(<<~JS)
      const originalFetch = window.fetch;
      let staleResponses = 0;
      window.fetch = (url, options) =>
        originalFetch(url, options).then(async (response) => {
          const query = new URL(url, location.origin).searchParams.get("query");
          if (query && query.length < 4) {
            await new Promise((resolve) => setTimeout(resolve, 500));
            staleResponses += 1;
            document.body.dataset.staleResponses = staleResponses;
          }
          return response;
        });
    JS
  end

  def settle_pending_renders
    page.evaluate_async_script(<<~JS)
      const done = arguments[0];
      requestAnimationFrame(() => requestAnimationFrame(done));
    JS
  end
end
