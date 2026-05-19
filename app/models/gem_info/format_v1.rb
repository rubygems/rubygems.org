# frozen_string_literal: true

class GemInfo
  class FormatV1 < Format
    def initialize
      super(
        version_key: :v1,
        gem_version_class: CompactIndex::GemVersion
      )
    end
  end
end
