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

    should "rank an exact name match first, even when a partial match has more downloads" do
      exact = create(:rubygem, name: "web", downloads: 5)
      create(:version, rubygem: exact, summary: "tiny web toolkit", description: "web")
      exact.update_search_vector

      _error, gems = DatabaseSearcher.new("web").search

      assert_equal exact, gems.first
    end

    # Regression guard: before the exact-name boost, "rails" ranked ~#10 on real data,
    # behind higher-download gems that merely contain "rails" (rails-html-sanitizer, etc.).
    should "rank a popular exact-name gem first ahead of higher-download partial matches" do
      {
        "rails-html-sanitizer" => 500_000,
        "factory_bot_rails"    => 400_000,
        "rspec-rails"          => 300_000,
        "rubocop-rails"        => 200_000
      }.each do |name, downloads|
        gem = create(:rubygem, name: name, downloads: downloads)
        create(:version, rubygem: gem, summary: "rails integration", description: "works with rails")
        gem.update_search_vector
      end

      _error, gems = DatabaseSearcher.new("rails").search

      assert_equal @rails, gems.first, "expected exact 'rails' gem first, got #{gems.first&.name}"
    end

    should "rank a name-prefix match above an incidental body match" do
      prefix = create(:rubygem, name: "rack-cors", downloads: 1)
      create(:version, rubygem: prefix, summary: "cross origin", description: "middleware")
      prefix.update_search_vector

      body_only = create(:rubygem, name: "middleware-tool", downloads: 100_000)
      create(:version, rubygem: body_only, summary: "uses rack internally", description: "rack adapter")
      body_only.update_search_vector

      _error, gems = DatabaseSearcher.new("rack").search
      names = gems.to_a.map(&:name)

      assert_operator names.index("rack-cors"), :<, names.index("middleware-tool")
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
