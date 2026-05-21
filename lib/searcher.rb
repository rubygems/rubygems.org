# frozen_string_literal: true

# Picks the search backend for a request: PostgreSQL full-text search
# (DatabaseSearcher) when the :postgres_search feature flag is enabled for the
# given actor, otherwise OpenSearch (ElasticSearcher). Both expose the same
# #search / #api_search / #suggestions interface.
module Searcher
  module_function

  def for(query, page: 1, actor: nil)
    searcher_class(actor).new(query, page: page)
  end

  def searcher_class(actor = nil)
    if FeatureFlag.enabled?(FeatureFlag::POSTGRES_SEARCH, actor)
      DatabaseSearcher
    else
      ElasticSearcher
    end
  end
end
