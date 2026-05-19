# frozen_string_literal: true

class GemInfo
  class FormatV2 < Format
    def initialize
      super(
        version_key: :v2,
        gem_version_class: CompactIndex::GemVersionV2
      )
    end
  end
end
