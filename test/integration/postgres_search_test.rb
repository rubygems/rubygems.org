# frozen_string_literal: true

require "test_helper"

# Exercises the PostgreSQL full-text search path end to end (no OpenSearch needed)
# when the :postgres_search feature flag is enabled.
class PostgresSearchTest < ActionDispatch::IntegrationTest
  setup do
    Flipper.features.each(&:remove)
    FeatureFlag.enable_globally(FeatureFlag::POSTGRES_SEARCH)

    @rails = create(:rubygem, name: "rails", downloads: 1000)
    create(:version, rubygem: @rails, summary: "Full-stack web framework", description: "Ruby on Rails")
    @rails.update_search_vector
  end

  teardown { Flipper.features.each(&:remove) }

  should "return matching gems on the web search page" do
    get search_path(query: "rails")

    assert_response :success
    assert_select "a.gems__gem h2.gems__gem__name", text: /rails/
  end

  should "return matching gems from the API search endpoint" do
    get api_v1_search_path(query: "framework", format: :json)

    assert_response :success
    names = response.parsed_body.pluck("name")

    assert_includes names, "rails"
  end

  should "return name prefix matches from the API autocomplete endpoint" do
    get "/api/v1/search/autocomplete", params: { query: "rai" }

    assert_response :success
    assert_includes response.parsed_body, "rails"
  end
end
