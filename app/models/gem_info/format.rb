# frozen_string_literal: true

class GemInfo
  class Format
    # Lifecycle statuses:
    #   :active   - fully operational: DB writes, S3 uploads, cache warming
    #   :draining - writes + uploads stop; existing S3 files still served (stale)
    #   :retired  - fully decommissioned; safe to remove and drop columns
    #
    # DB writes and S3 uploads are coupled: the versions file reads checksums
    # from the DB, so you cannot upload without writing.
    STATUSES = %i[active draining retired].freeze

    attr_reader :cache_prefix, :stats_key, :checksum_column, :yanked_checksum_column,
                :status, :gem_version_class

    def initialize(version_key:, gem_version_class:, status: :active)
      @cache_prefix = version_key == :v1 ? "info" : "info_#{version_key}"
      @stats_key = version_key == :v1 ? "compact_index.memcached.info" : "compact_index.memcached.info_#{version_key}"
      @checksum_column = version_key == :v1 ? :info_checksum : :"info_checksum_#{version_key}"
      @yanked_checksum_column = version_key == :v1 ? :yanked_info_checksum : :"yanked_info_checksum_#{version_key}"
      @gem_version_class = gem_version_class
      @status = status
      raise ArgumentError, "Invalid status: #{status}" unless STATUSES.include?(status)
    end

    def active?   = status == :active
    def draining? = status == :draining
    def retired?  = status == :retired

    def enabled?
      active?
    end

    def serving?
      active? || draining?
    end

    # Build a GemVersion from a row hash using the fields declared on the version class.
    def gem_version_from_row(row)
      args = gem_version_class.fields.map { |field| row[field] }
      gem_version_class.new(*args)
    end
  end
end
