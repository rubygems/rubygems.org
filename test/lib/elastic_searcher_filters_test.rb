# frozen_string_literal: true

require "test_helper"

class ElasticSearcherFiltersTest < ActiveSupport::TestCase
  include SearchKickHelper

  setup do
    # Each sort orders these differently, and "Zeta-gem" is capitalized so a
    # case-sensitive name sort would put it first.
    create_gem "alpha-gem", downloads: 100, updated: 2.days.ago, licenses: ["MIT"]
    create_gem "beta-gem", downloads: 200, updated: 8.days.ago, licenses: ["Apache-2.0"]
    create_gem "Zeta-gem", downloads: 300, updated: 3.days.ago, licenses: %w[GPL-3.0 MIT]
    create_gem "old-gem", downloads: 50, updated: 400.days.ago, licenses: ["MIT"]
    yanked = create(:rubygem, name: "yanked-gem", downloads: 1000)
    create(:version, :yanked, rubygem: yanked, licenses: ["MIT"])
    Rubygem.reindex
  end

  def create_gem(name, downloads:, updated:, licenses:)
    rubygem = create(:rubygem, name:, downloads:)
    create(:version, rubygem:, licenses:)
    rubygem.update_column(:updated_at, updated)
  end

  def search(**filters)
    error, result = ElasticSearcher.new("gem", filters: SearchFilters.new(**filters)).search

    assert_nil error
    result
  end

  def names(**filters)
    search(**filters).map(&:name)
  end

  context "sort" do
    should "order by downloads, most first" do
      assert_equal %w[Zeta-gem beta-gem alpha-gem old-gem], names(sort: "downloads")
    end

    should "order by last update, most recent first" do
      assert_equal %w[alpha-gem Zeta-gem beta-gem old-gem], names(sort: "updated")
    end

    should "order by name, ignoring case" do
      assert_equal %w[alpha-gem beta-gem old-gem Zeta-gem], names(sort: "name")
    end
  end

  context "updated filter" do
    should "keep gems updated within the period" do
      assert_equal %w[Zeta-gem alpha-gem], names(updated: "week", sort: "downloads")
      assert_equal %w[Zeta-gem beta-gem alpha-gem], names(updated: "month", sort: "downloads")
      assert_equal 3, search(updated: "year").total_count
    end
  end

  context "license filter" do
    should "match any selected license, including on multi-license gems" do
      assert_equal %w[Zeta-gem alpha-gem old-gem], names(licenses: ["MIT"], sort: "downloads")
      assert_equal %w[Zeta-gem], names(licenses: ["GPL-3.0"])
      assert_equal %w[Zeta-gem beta-gem alpha-gem old-gem], names(licenses: %w[MIT Apache-2.0], sort: "downloads")
    end

    should "not match licenses by prefix or case" do
      assert_empty names(licenses: ["mit"])
      assert_empty names(licenses: ["GPL"])
    end
  end

  context "combined filters" do
    should "require every filter to match" do
      assert_equal %w[Zeta-gem alpha-gem], names(updated: "week", licenses: ["MIT"], sort: "downloads")

      result = search(updated: "week", licenses: ["Apache-2.0"])

      assert_empty result.to_a
      assert_equal 0, result.total_count
    end

    should "still exclude yanked gems" do
      refute_includes names(licenses: ["MIT"]), "yanked-gem"
    end
  end

  context "facet counts" do
    should "apply the other facets but not their own" do
      filters = SearchFilters.new(updated: "week", licenses: ["Apache-2.0"])
      _, result = ElasticSearcher.new("gem", filters:).search
      aggregations = result.response["aggregations"]

      # Licenses among gems updated this week; the Apache-2.0 selection is ignored.
      assert_equal({ "MIT" => 2, "GPL-3.0" => 1, "Apache-2.0" => nil }, filters.license_counts(aggregations))
      # Periods among Apache-2.0 gems; the week selection is ignored.
      assert_equal({ "week" => 0, "month" => 1, "year" => 1 }, filters.updated_counts(aggregations))
    end

    should "count all matching gems without filters" do
      filters = SearchFilters.new
      _, result = ElasticSearcher.new("gem", filters:).search
      aggregations = result.response["aggregations"]

      assert_equal({ "MIT" => 3, "Apache-2.0" => 1, "GPL-3.0" => 1 }, filters.license_counts(aggregations))
      assert_equal({ "week" => 2, "month" => 3, "year" => 3 }, filters.updated_counts(aggregations))
    end
  end

  context "api_search" do
    should "return unfiltered results" do
      assert_equal 4, ElasticSearcher.new("gem").api_search.size
    end
  end
end
