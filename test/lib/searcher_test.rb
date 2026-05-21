# frozen_string_literal: true

require "test_helper"

class SearcherTest < ActiveSupport::TestCase
  setup { Flipper.features.each(&:remove) }
  teardown { Flipper.features.each(&:remove) }

  context ".searcher_class" do
    should "default to ElasticSearcher when the flag is disabled" do
      assert_equal ElasticSearcher, Searcher.searcher_class
    end

    should "return DatabaseSearcher when the flag is enabled globally" do
      FeatureFlag.enable_globally(FeatureFlag::POSTGRES_SEARCH)

      assert_equal DatabaseSearcher, Searcher.searcher_class
    end

    should "return DatabaseSearcher only for actors the flag is enabled for" do
      beta = create(:user)
      regular = create(:user)
      FeatureFlag.enable_for_actor(FeatureFlag::POSTGRES_SEARCH, beta)

      assert_equal DatabaseSearcher, Searcher.searcher_class(beta)
      assert_equal ElasticSearcher, Searcher.searcher_class(regular)
    end
  end

  context ".for" do
    should "build a searcher instance for the query" do
      FeatureFlag.enable_globally(FeatureFlag::POSTGRES_SEARCH)

      assert_instance_of DatabaseSearcher, Searcher.for("rails", page: 1)
    end
  end
end
