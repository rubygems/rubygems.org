# frozen_string_literal: true

# TODO: Remove this patch when we upgrade to opensearch-ruby 4.0.0+
# because once we do we will no longer have multi_json as a dependency.

require "opensearch/transport/transport/serializer/multi_json"

module OpenSearchMultiJsonSerializerPatch
  def load(string, options = {})
    ::MultiJSON.parse(string, options)
  end

  def dump(object, options = {})
    ::MultiJSON.generate(object, options)
  end
end

OpenSearch::Transport::Transport::Serializer::MultiJson.prepend(OpenSearchMultiJsonSerializerPatch)
