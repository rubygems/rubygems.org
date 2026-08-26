# frozen_string_literal: true

class Advisory::OSV < Advisory
  def self.feature_flag = FeatureFlag::OSV_ADVISORIES

  enum :severity, { low: "low", moderate: "moderate", high: "high", critical: "critical" }, validate: { allow_nil: true }

  private

  def range_includes?(range, gem_version)
    return false unless range.is_a?(Hash)

    unless range["introduced"] == "0"
      introduced = parse_bound(range["introduced"])
      return false if introduced.nil?
      return false if gem_version < introduced
    end

    if range.key?("fixed")
      fixed = parse_bound(range["fixed"])
      return false if fixed.nil?
      return gem_version < fixed
    end

    if range.key?("last_affected")
      last_affected = parse_bound(range["last_affected"])
      return false if last_affected.nil?
      return gem_version <= last_affected
    end

    true
  end

  def parse_bound(value)
    return nil if value.blank?

    Gem::Version.new(value.to_s)
  rescue ArgumentError
    nil
  end
end
