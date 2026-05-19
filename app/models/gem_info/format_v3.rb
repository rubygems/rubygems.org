# frozen_string_literal: true

class GemInfo
  class FormatV3 < Format
    def initialize
      super(
        version_key: :v3,
        gem_version_class: CompactIndex::GemVersionV3
      )
    end
  end
end
