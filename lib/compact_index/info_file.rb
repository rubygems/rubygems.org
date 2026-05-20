# frozen_string_literal: true

module CompactIndex
  class InfoFile
    def initialize(versions)
      @versions = versions
    end

    def contents
      @versions.inject(+"---\n") do |output, version|
        output << to_line(version) << "\n"
      end
    end

    private

    def to_line(version)
      line = +"#{version.number_and_platform} #{deps_line(version)}|checksum:#{version.checksum}"
      line << ",ruby:#{format_requirement(version.ruby_version)}" if version.ruby_version && version.ruby_version != ">= 0"
      line << ",rubygems:#{format_requirement(version.rubygems_version)}" if version.rubygems_version && version.rubygems_version != ">= 0"

      (version.class.fields - GemVersion::BASE_FIELDS).each do |field|
        value = version[field]
        line << ",#{field}:#{value}" if value
      end

      line
    end

    def deps_line(version)
      return "" if version.dependencies.nil?

      version.dependencies.map do |d|
        [d[:gem], format_requirement(d.version_and_platform)].join(":")
      end.join(",")
    end

    def format_requirement(requirement)
      parts = requirement.split(", ")
      parts.sort!
      parts.join("&")
    end
  end
end
