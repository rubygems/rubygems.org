# frozen_string_literal: true

require "test_helper"

class SearchFiltersTest < ActiveSupport::TestCase
  def from_params(params)
    SearchFilters.from_params(ActionController::Parameters.new(params))
  end

  context ".from_params" do
    should "default to relevance with no filters" do
      filters = from_params({})

      assert_equal "relevance", filters.sort
      assert_nil filters.updated
      assert_empty filters.licenses
      refute_predicate filters, :active?
      assert_nil filters.post_filter
      assert_nil filters.sort_clause
    end

    should "keep known values" do
      filters = from_params(sort: "downloads", updated: "month", license: %w[MIT Apache-2.0])

      assert_equal "downloads", filters.sort
      assert_equal "month", filters.updated
      assert_equal %w[MIT Apache-2.0], filters.licenses
      assert_predicate filters, :active?
    end

    should "drop unknown sort and updated values instead of raising" do
      filters = from_params(sort: "_score desc", updated: "decade")

      assert_equal "relevance", filters.sort
      assert_nil filters.updated
    end

    should "accept a single license string" do
      assert_equal ["MIT"], from_params(license: "MIT").licenses
    end

    should "ignore hash, blank and duplicate license values" do
      assert_empty from_params(license: { "a" => "MIT" }).licenses
      assert_equal ["MIT"], from_params(license: ["", "MIT", "MIT"]).licenses
    end

    should "cap the number of licenses" do
      licenses = Array.new(SearchFilters::MAX_LICENSES + 5) { |i| "L#{i}" }

      assert_equal SearchFilters::MAX_LICENSES, from_params(license: licenses).licenses.size
    end
  end

  context "#to_params" do
    should "omit the default sort and empty filters" do
      assert_empty from_params(sort: "relevance").to_params
    end

    should "round-trip through from_params" do
      filters = from_params(sort: "name", updated: "week", license: %w[MIT GPL-3.0])
      round_tripped = from_params(filters.to_params)

      assert_equal({ sort: "name", updated: "week", license: %w[MIT GPL-3.0] }, filters.to_params)
      assert_equal filters.to_params, round_tripped.to_params
    end
  end

  context "#with" do
    should "change one filter and keep the rest" do
      filters = from_params(sort: "downloads", updated: "year", license: %w[MIT GPL-3.0])
      changed = filters.with(licenses: ["GPL-3.0"])

      assert_equal({ sort: "downloads", updated: "year", license: ["GPL-3.0"] }, changed.to_params)
      assert_equal %w[MIT GPL-3.0], filters.licenses
    end
  end

  context "#license_counts" do
    should "keep selected licenses missing from the top buckets with an unknown count" do
      filters = from_params(license: %w[MIT WTFPL])
      aggregations = { "license_facet" => { "values" => { "buckets" => ["key" => "MIT", "doc_count" => 4] } } }

      assert_equal({ "MIT" => 4, "WTFPL" => nil }, filters.license_counts(aggregations))
    end
  end
end
