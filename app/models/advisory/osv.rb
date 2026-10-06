# frozen_string_literal: true

class Advisory::OSV < Advisory
  def self.feature_flag = FeatureFlag::OSV_ADVISORIES

  enum :severity, { low: "low", moderate: "moderate", high: "high", critical: "critical" }, validate: { allow_nil: true }

  def malware?
    identifier.to_s.start_with?("MAL-")
  end

  private

  def range_includes?(range, gem_version)
    AffectedRange.new(
      introduced: range["introduced"],
      fixed: range["fixed"],
      last_affected: range["last_affected"]
    ).include?(gem_version)
  end
end
