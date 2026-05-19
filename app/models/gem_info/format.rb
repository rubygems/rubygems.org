# frozen_string_literal: true

class GemInfo
  class Format
    attr_reader :version_key, :cache_prefix, :stats_key, :checksum_column, :yanked_checksum_column,
                :gem_version_class, :active

    def initialize(version_key:, gem_version_class:, active: true)
      @version_key = version_key
      @cache_prefix = version_key == :v1 ? "info" : "info_#{version_key}"
      @stats_key = version_key == :v1 ? "compact_index.memcached.info" : "compact_index.memcached.info_#{version_key}"
      @checksum_column = version_key == :v1 ? :info_checksum : :"info_checksum_#{version_key}"
      @yanked_checksum_column = version_key == :v1 ? :yanked_info_checksum : :"yanked_info_checksum_#{version_key}"
      @gem_version_class = gem_version_class
      @active = active
    end

    def active?
      @active
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

    # Build a GemVersion from a row hash using the fields declared on the version class.
    def gem_version_from_row(row)
      args = gem_version_class.fields.map { |field| row[field] }
      gem_version_class.new(*args)
    end
  end
end
