# frozen_string_literal: true

module CompactIndexVersions
  extend ActiveSupport::Concern

  class_methods do
    def compact_index_versions(date, version: self::CURRENT_VERSION)
      config = self::VERSIONS.fetch(version)
      checksum_column = config[:checksum_column]
      yanked_checksum_column = config[:yanked_checksum_column]

      query = ["(SELECT r.name, v.created_at as date, v.#{checksum_column} as info_checksum, v.number, v.platform
                FROM rubygems AS r, versions AS v
                WHERE v.rubygem_id = r.id AND
                      v.created_at > ?)
                UNION
                (SELECT r.name, v.yanked_at as date, v.#{yanked_checksum_column} as info_checksum, '-'||v.number, v.platform
                FROM rubygems AS r, versions AS v
                WHERE v.rubygem_id = r.id AND
                      v.indexed is false AND
                      v.yanked_at > ?)
                ORDER BY date, number, platform, name", date, date]

      map_gem_versions(execute_raw_sql(query).map { |v| [v["name"], [v]] })
    end

    def each_compact_index_public_version(updated_at, version: self::CURRENT_VERSION, &block)
      # Stream one CompactIndex::Gem at a time to avoid loading every version into memory.
      # When called without a block, return an Enumerator so callers can use .to_a, .map, etc.
      return enum_for(__method__, updated_at, version:) unless block

      config = self::VERSIONS.fetch(version)
      checksum_column = config[:checksum_column]
      yanked_checksum_column = config[:yanked_checksum_column]

      query = ["SELECT r.name, v.indexed, COALESCE(v.yanked_at, v.created_at) as stamp,
                       v.sha256, COALESCE(v.#{yanked_checksum_column}, v.#{checksum_column}) as info_checksum,
                       v.number, v.platform
                FROM rubygems AS r, versions AS v
                WHERE v.rubygem_id = r.id AND
                      (v.created_at <= ? OR v.yanked_at <= ?)
                ORDER BY r.name COLLATE \"C\", stamp, v.number, v.platform", updated_at, updated_at]

      execute_raw_sql(query)
        .chunk_while { |a, b| a["name"] == b["name"] }
        .each { |rows| public_compact_index_gem(rows.first["name"], rows, &block) }
    end

    def compact_index_public_versions(updated_at, version: self::CURRENT_VERSION)
      each_compact_index_public_version(updated_at, version:).to_a
    end

    def execute_raw_sql(query)
      sanitized_sql = ActiveRecord::Base.send(:sanitize_sql_array, query)
      ActiveRecord::Base.connection.execute(sanitized_sql)
    end

    def map_gem_versions(versions_by_gem)
      versions_by_gem.map { |gem_name, versions| build_compact_index_gem(gem_name, versions) }
    end

    def public_compact_index_gem(gem_name, versions)
      info_checksum = versions.last["info_checksum"]
      versions.select! { |v| v["indexed"] == true }
      return if versions.empty?

      # Set all versions' info_checksum to work around https://github.com/bundler/compact_index/pull/20
      versions.each { |v| v["info_checksum"] = info_checksum }
      yield build_compact_index_gem(gem_name, versions)
    end

    def build_compact_index_gem(gem_name, versions)
      compact_index_versions = versions.map do |version|
        CompactIndex::GemVersion.new(version["number"],
          version["platform"],
          version["sha256"],
          version["info_checksum"])
      end
      CompactIndex::Gem.new(gem_name, compact_index_versions)
    end

    private :map_gem_versions, :public_compact_index_gem, :build_compact_index_gem, :execute_raw_sql
  end
end
