# frozen_string_literal: true

class GemInfo
  class FormatV4 < Format
    def initialize
      super(
        version_key: :v4,
        gem_version_class: CompactIndex::GemVersionV4
      )
    end
  end
end
