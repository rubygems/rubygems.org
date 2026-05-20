# frozen_string_literal: true

module CompactIndex
  class Format
    attr_reader :version_key, :active,
                :checksum_column, :yanked_checksum_column,
                :cache_prefix, :stats_key

    def initialize(version_key:, gem_version_class: nil, active: true)
      @version_key = version_key
      @gem_version_class = gem_version_class
      @active = active

      v1 = version_key == :v1
      @checksum_column          = v1 ? :info_checksum          : :"info_checksum_#{version_key}"
      @yanked_checksum_column   = v1 ? :yanked_info_checksum   : :"yanked_info_checksum_#{version_key}"
      @cache_prefix             = v1 ? "info"                  : "info_#{version_key}"
      @stats_key                = v1 ? "compact_index.memcached.info" : "compact_index.memcached.info_#{version_key}"
    end

    def active?
      @active
    end

    def gem_version_class
      @gem_version_class || CompactIndex::GemVersion
    end

    def s3_path(resource)
      version_key == :v1 ? resource : "#{version_key}/#{resource}"
    end

    def versions_file_path
      if version_key == :v1
        Rails.application.config.rubygems["versions_file_location"]
      else
        Rails.application.config.rubygems["versions_file_location_#{version_key}"]
      end
    end

    # Build a GemVersion from a row hash using the version's declared fields.
    def gem_version_from_row(row)
      args = gem_version_class.fields.map { |field| row[field] }
      gem_version_class.new(*args)
    end
  end
end
