# frozen_string_literal: true

require "test_helper"

# End-to-end wiring check for SearchComparison: confirms it can pull ranked names from
# both the live OpenSearch (ElasticSearcher) and PostgreSQL (DatabaseSearcher) backends
# and produce metrics. Requires OpenSearch (handled by SearchKickHelper).
class SearchComparisonBackendsTest < ActiveSupport::TestCase
  include SearchKickHelper

  setup do
    @rails = create(:rubygem, name: "rails", downloads: 1000)
    create(:version, rubygem: @rails, summary: "Full-stack web framework", description: "Ruby on Rails")
    @rack = create(:rubygem, name: "rack", downloads: 10)
    create(:version, rubygem: @rack, summary: "Modular web server interface", description: "web framework toolkit")

    [@rails, @rack].each do |gem|
      gem.update_search_vector
      gem.reindex(refresh: true)
    end
  end

  should "return matching names from both backends and high agreement for an exact name" do
    row = SearchComparison.new(top_n: 5).compare("rails")

    assert_nil row.error
    assert_includes row.es_names, "rails"
    assert_includes row.pg_names, "rails"
    assert_operator row.jaccard, :>, 0.0
  end

  should "produce a report with an aggregate summary across queries" do
    report = SearchComparison.new(top_n: 5).report(%w[rails framework])

    assert_equal 2, report.summary[:queries]
    assert_equal 2, report.summary[:compared]
    assert_equal 0, report.summary[:failures]
  end
end
