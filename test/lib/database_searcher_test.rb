# frozen_string_literal: true

require "test_helper"

class DatabaseSearcherTest < ActiveSupport::TestCase
  setup do
    @rails = create(:rubygem, name: "rails", downloads: 1000)
    create(:version, rubygem: @rails, summary: "Full-stack web framework", description: "Ruby on Rails")

    @rack = create(:rubygem, name: "rack", downloads: 10)
    create(:version, rubygem: @rack, summary: "Modular Ruby web server interface", description: "web framework toolkit")

    @sidekiq = create(:rubygem, name: "sidekiq", downloads: 50)
    create(:version, rubygem: @sidekiq, summary: "Background jobs", description: "redis queue processor")

    [@rails, @rack, @sidekiq].each(&:update_search_vector)
  end

  context "#search" do
    should "match on gem name" do
      _error, gems = DatabaseSearcher.new("rails").search

      assert_includes gems, @rails
      refute_includes gems, @sidekiq
    end

    should "match on summary and description" do
      _error, gems = DatabaseSearcher.new("web framework").search

      assert_includes gems, @rails
      assert_includes gems, @rack
      refute_includes gems, @sidekiq
    end

    should "return a paginated relation exposing total_count" do
      _error, gems = DatabaseSearcher.new("framework").search

      assert_respond_to gems, :total_count
      assert_operator gems.total_count, :>=, 1
    end

    should "rank name matches above body matches and boost by downloads" do
      _error, gems = DatabaseSearcher.new("web framework").search

      # rails has the higher download count, so it should outrank rack
      assert_equal @rails, gems.first
    end

    should "exclude yanked (unindexed) gems" do
      @rack.update!(indexed: false)
      _error, gems = DatabaseSearcher.new("web framework").search

      refute_includes gems, @rack
    end

    should "return no results for a blank query" do
      _error, gems = DatabaseSearcher.new("").search

      assert_empty gems
    end
  end

  context "#api_search" do
    should "return source hashes with the API fields" do
      results = DatabaseSearcher.new("rails").api_search

      assert_equal 1, results.size
      result = results.first

      assert_equal "rails", result[:name]
      assert_equal DatabaseSearcher::API_FIELDS.sort, result.keys.sort
    end
  end

  context "#suggestions" do
    should "return name prefix matches ordered by downloads" do
      racecar = create(:rubygem, name: "racecar", downloads: 5)
      create(:version, rubygem: racecar)
      racecar.update_search_vector

      results = DatabaseSearcher.new("rac").suggestions

      assert_includes results, "rack"
      assert_includes results, "racecar"
      # rack has more downloads than racecar
      assert_operator results.index("rack"), :<, results.index("racecar")
    end

    should "return an empty array for a blank query" do
      assert_empty DatabaseSearcher.new("").suggestions
    end
  end
end
