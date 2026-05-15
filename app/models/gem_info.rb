# frozen_string_literal: true

class GemInfo
  def initialize(rubygem_name, cached: true)
    @rubygem_name = rubygem_name
    @cached = cached
  end

  def compact_index_info
    cached_compact_index_info(version: 1)
  end

  def info_checksum
    checksum_for(requirements_and_dependencies, version: 1)
  end

  def info_checksum_v2
    checksum_for(requirements_and_dependencies, version: 2)
  end

  def compact_index_info_v2
    cached_compact_index_info(version: 2)
  end

  def info_checksums
    rows = requirements_and_dependencies

    {
      info_checksum: checksum_for(rows, version: 1),
      info_checksum_v2: checksum_for(rows, version: 2)
    }
  end

  def self.ordered_names(cached: true)
    if cached && (names = Rails.cache.read("names"))
      StatsD.increment "compact_index.memcached.names.hit"
    else
      StatsD.increment "compact_index.memcached.names.miss"
      names = Rubygem.with_versions.order(:name).pluck(:name)
      Rails.cache.write("names", names)
    end
    names
  end

  def self.compact_index_versions(date)
    compact_index_versions_query(date, checksum_col: "info_checksum", yanked_checksum_col: "yanked_info_checksum")
  end

  def self.compact_index_versions_v2(date)
    compact_index_versions_query(date, checksum_col: "info_checksum_v2", yanked_checksum_col: "yanked_info_checksum_v2")
  end

  def self.compact_index_versions_query(date, checksum_col:, yanked_checksum_col:)
    query = ["(SELECT r.name, v.created_at as date, v.#{checksum_col} as info_checksum, v.number, v.platform
              FROM rubygems AS r, versions AS v
              WHERE v.rubygem_id = r.id AND
                    v.created_at > ?)
              UNION
              (SELECT r.name, v.yanked_at as date, v.#{yanked_checksum_col} as info_checksum, '-'||v.number, v.platform
              FROM rubygems AS r, versions AS v
              WHERE v.rubygem_id = r.id AND
                    v.indexed is false AND
                    v.yanked_at > ?)
              ORDER BY date, number, platform, name", date, date]

    map_gem_versions(execute_raw_sql(query).map { |v| [v["name"], [v]] })
  end

  def self.compact_index_public_versions(updated_at)
    query = ["SELECT r.name, v.indexed, COALESCE(v.yanked_at, v.created_at) as stamp,
                     v.sha256, COALESCE(v.yanked_info_checksum, v.info_checksum) as info_checksum,
                     v.number, v.platform
              FROM rubygems AS r, versions AS v
              WHERE v.rubygem_id = r.id AND
                    (v.created_at <= ? OR v.yanked_at <= ?)
              ORDER BY r.name, stamp, v.number, v.platform", updated_at, updated_at]

    versions_by_gem = execute_raw_sql(query).group_by { |v| v["name"] }
    versions_by_gem.each_value do |versions|
      info_checksum = versions.last["info_checksum"]
      versions.select! { |v| v["indexed"] == true }
      # Set all versions' info_checksum to work around https://github.com/bundler/compact_index/pull/20
      versions.each { |v| v["info_checksum"] = info_checksum }
    end
    versions_by_gem.reject! { |_, versions| versions.empty? }

    map_gem_versions(versions_by_gem)
  end

  def self.execute_raw_sql(query)
    sanitized_sql = ActiveRecord::Base.send(:sanitize_sql_array, query)
    ActiveRecord::Base.connection.execute(sanitized_sql)
  end

  def self.map_gem_versions(versions_by_gem)
    versions_by_gem.map do |gem_name, versions|
      compact_index_versions = versions.map do |version|
        CompactIndex::GemVersion.new(version["number"],
          version["platform"],
          version["sha256"],
          version["info_checksum"])
      end
      CompactIndex::Gem.new(gem_name, compact_index_versions)
    end
  end

  private_class_method :map_gem_versions, :execute_raw_sql, :compact_index_versions_query

  private

  DEPENDENCY_NAMES_INDEX = 8

  DEPENDENCY_REQUIREMENTS_INDEX = 7

  def cached_compact_index_info(version:)
    cache_key = compact_index_info_cache_key(version)
    stats_key = compact_index_info_stats_key(version)

    if @cached && (info = Rails.cache.read(cache_key))
      StatsD.increment "#{stats_key}.hit"
      info
    else
      StatsD.increment "#{stats_key}.miss"
      compact_index_info_for(requirements_and_dependencies, version:).tap do |compact_index_info|
        Rails.cache.write(cache_key, compact_index_info)
      end
    end
  end

  def compact_index_info_cache_key(version)
    version == 1 ? "info/#{@rubygem_name}" : "info_v2/#{@rubygem_name}"
  end

  def compact_index_info_stats_key(version)
    version == 1 ? "compact_index.memcached.info" : "compact_index.memcached.info_v2"
  end

  def checksum_for(rows, version:)
    compact_index_info = CompactIndex.info(compact_index_info_for(rows, version:))
    Digest::MD5.hexdigest(compact_index_info)
  end

  def compact_index_info_for(rows, version:)
    rows.map do |row|
      gem_version_from_row(row, version:)
    end
  end

  def gem_version_from_row(row, version:)
    deps = []
    if row[DEPENDENCY_REQUIREMENTS_INDEX]
      reqs = row[DEPENDENCY_REQUIREMENTS_INDEX].split("@")
      dep_names = row[DEPENDENCY_NAMES_INDEX].split(",")
      raise "BUG: different size of reqs and dep_names." unless reqs.size == dep_names.size
      dep_names.zip(reqs).each do |name, req|
        deps << CompactIndex::Dependency.new(name, req) unless name == "0"
      end
    end

    name, platform, checksum, info_checksum, ruby_version, rubygems_version, created_at, = row
    CompactIndex::GemVersion.new(
      name,
      platform,
      Version._sha256_hex(checksum),
      info_checksum,
      deps,
      ruby_version,
      rubygems_version,
      version == 2 ? created_at&.utc&.iso8601 : nil
    )
  end

  def requirements_and_dependencies
    @requirements_and_dependencies ||= begin
      group_by_columns = "number, platform, sha256, info_checksum, required_ruby_version, required_rubygems_version, versions.created_at"

      dep_req_agg = "string_agg(dependencies.requirements, '@' ORDER BY rubygems_dependencies.name, dependencies.id)"

      dep_name_agg = "string_agg(coalesce(rubygems_dependencies.name, '0'), ',' ORDER BY rubygems_dependencies.name) AS dep_name"

      Rubygem.joins("LEFT JOIN versions ON versions.rubygem_id = rubygems.id
          LEFT JOIN dependencies ON dependencies.version_id = versions.id
          LEFT JOIN rubygems rubygems_dependencies
            ON rubygems_dependencies.id = dependencies.rubygem_id
            AND dependencies.scope = 'runtime'")
        .where("rubygems.name = ? AND versions.indexed = true", @rubygem_name)
        .group(Arel.sql(group_by_columns))
        .order(Arel.sql("versions.created_at, number, platform, dep_name"))
        .pluck(Arel.sql("#{group_by_columns}, #{dep_req_agg}, #{dep_name_agg}"))
    end
  end
end
