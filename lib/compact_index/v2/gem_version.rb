# frozen_string_literal: true

require_relative "../gem_version"

module CompactIndex
  module V2
    class GemVersion < CompactIndex::GemVersion
      attribute :created_at
    end
  end
end
