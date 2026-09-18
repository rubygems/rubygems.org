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

    assert @form.has_no_selector?("[role='option']")
  end

  test "suggestions don't appear unless the search field is focused" do
    find("h1").click

    assert @form.has_no_selector?("[role='option']")
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
    option = @form.first("[role='option']", text: "rubocop")
    option.hover

    @form.assert_selector "#{SUGGESTIONS}[aria-activedescendant]"

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
    @form.assert_selector "#{SUGGESTIONS}[aria-activedescendant='suggest-0']"

    assert_selector "body[data-stale-responses]"
    settle_pending_renders

    assert_equal "suggest-0", active_descendant
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
