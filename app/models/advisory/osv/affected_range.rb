# frozen_string_literal: true

class Advisory::OSV
  AffectedRange = Data.define(:introduced, :fixed, :last_affected) do
    def include?(gem_version)
      return false unless covers_introduced?(gem_version)

      unless fixed.nil?
        bound = parse_bound(fixed)
        return false if bound.nil?

        return gem_version < bound
      end

      unless last_affected.nil?
        bound = parse_bound(last_affected)
        return false if bound.nil?

        return gem_version <= bound
      end

      true
    end

    def as_json(*)
      super.compact
    end

    private

    def covers_introduced?(gem_version)
      return true if introduced == "0"

      bound = parse_bound(introduced)
      return false if bound.nil?

      gem_version >= bound
    end

    def parse_bound(value)
      return nil if value.blank?

      Gem::Version.new(value.to_s)
    rescue ArgumentError
      nil
    end
  end
end
