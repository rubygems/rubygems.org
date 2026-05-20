# frozen_string_literal: true

# Vendored from https://github.com/rubygems/compact_index v0.15.0

require_relative "compact_index/gem"
require_relative "compact_index/gem_version"
require_relative "compact_index/dependency"
require_relative "compact_index/info_file"
require_relative "compact_index/versions_file"
require_relative "compact_index/format"
require_relative "compact_index/v2/gem_version"

module CompactIndex
  CURRENT_FORMAT = Format.new(version_key: :v1)
  NEXT_FORMAT    = Format.new(version_key: :v2, gem_version_class: V2::GemVersion)

  def self.active_formats
    [CURRENT_FORMAT, NEXT_FORMAT].compact
  end

  # The format served to clients. Controlled by Flipper flag.
  # When :compact_index_next_format is enabled, serves NEXT_FORMAT.
  # Otherwise serves CURRENT_FORMAT.
  def self.serving_format
    if NEXT_FORMAT && Flipper.enabled?(:compact_index_next_format)
      NEXT_FORMAT
    else
      CURRENT_FORMAT
    end
  end

  def self.names(gem_names)
    gem_names.join("\n").prepend("---\n") << "\n"
  end

  def self.versions(versions_file, gems = nil, args = {})
    versions_file.contents(gems, args)
  end

  def self.info(versions)
    InfoFile.new(versions).contents
  end
end
