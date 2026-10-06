# frozen_string_literal: true

# OSV schema: https://ossf.github.io/osv-schema
class Advisory::OSV::Mapper
  ECOSYSTEM = "RubyGems"
  GITHUB_URL_PREFIX = "https://github.com/advisories/"
  OSV_URL_PREFIX = "https://osv.dev/vulnerability/"
  RANGE_TYPES = %w[ECOSYSTEM SEMVER].freeze
  RANGE_EVENTS = %w[introduced fixed last_affected].freeze

  def self.call(document)
    new(document).records
  end

  def initialize(document)
    @document = document.to_h.deep_stringify_keys
  end

  def records
    return [] if identifier.blank? || modified_at.blank?

    packages.map do |name, ranges|
      {
        identifier:,
        rubygem_name: name,
        aliases:,
        summary:,
        severity:,
        url:,
        published_at:,
        modified_at:,
        withdrawn_at:,
        ranges: ranges.map(&:as_json)
      }
    end
  end

  private

  def identifier
    @document["id"].presence
  end

  def aliases
    Array(@document["aliases"]).map(&:to_s)
  end

  def summary
    @document["summary"].presence || identifier
  end

  def severity
    raw = @document.dig("database_specific", "severity")&.to_s&.downcase
    raw if Advisory::OSV.severities.key?(raw)
  end

  def url
    "#{identifier.start_with?('GHSA-') ? GITHUB_URL_PREFIX : OSV_URL_PREFIX}#{identifier}"
  end

  def published_at
    parse_time(@document["published"])
  end

  def modified_at
    parse_time(@document["modified"])
  end

  def withdrawn_at
    parse_time(@document["withdrawn"])
  end

  # One record per gem: several affected entries for the same name are merged.
  # Keep ECOSYSTEM/SEMVER ranges and enumerated versions; GIT ranges are dropped.
  def packages
    Array(@document["affected"]).each_with_object({}) do |entry, grouped|
      package = entry["package"] || {}
      next unless package["ecosystem"] == ECOSYSTEM

      name = package["name"].presence
      next unless name

      grouped[name] ||= []
      grouped[name].concat(normalized_ranges(entry))
      grouped[name].concat(normalized_versions(entry))
    end
  end

  def normalized_ranges(entry)
    Array(entry["ranges"]).flat_map do |range|
      next [] unless RANGE_TYPES.include?(range["type"])

      Array(range["events"])
        .filter_map { |event| event.slice(*RANGE_EVENTS).presence }
        .slice_when { |_, event| event.key?("introduced") }
        .map { |group| affected_range(group.reduce({}, :merge)) }
    end
  end

  def normalized_versions(entry)
    Array(entry["versions"]).filter_map do |version|
      affected_range("introduced" => version, "last_affected" => version) if version.present?
    end
  end

  def affected_range(bounds)
    Advisory::OSV::AffectedRange.new(
      introduced: bounds["introduced"],
      fixed: bounds["fixed"],
      last_affected: bounds["last_affected"]
    )
  end

  def parse_time(value)
    Time.iso8601(value.to_s)
  rescue ArgumentError
    nil
  end
end
