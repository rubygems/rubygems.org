# frozen_string_literal: true

# TODO: Remove this patch when we upgrade to opensearch-ruby 4.0.0+
# because once we do we will no longer have multi_json as a dependency.

require "sawyer/serializer"

module SawyerMultiJsonSerializerPatch
  def multi_json
    require "multi_json"
    new(::MultiJSON, :generate, :parse)
  end
end

Sawyer::Serializer.singleton_class.prepend(SawyerMultiJsonSerializerPatch)
