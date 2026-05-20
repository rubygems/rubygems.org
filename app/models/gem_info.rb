# frozen_string_literal: true

class GemInfo
  def initialize(rubygem_name, cached: true)
    @rubygem_name = rubygem_name
    @cached = cached
  end

  def compact_index_info
    compact_index_info_for(CompactIndex::CURRENT_FORMAT)
  end

  def compact_index_info_for(format)
    cache_key = "#{format.cache_prefix}/#{@rubygem_name}"

    if @cached && (info = Rails.cache.read(cache_key))
      StatsD.increment "#{format.stats_key}.hit"
      info
    else
      StatsD.increment "#{format.stats_key}.miss"
      build_gem_versions(requirements_and_dependencies, format).tap do |compact_index_info|
        Rails.cache.write(cache_key, compact_index_info)
      end
    end
  end

  def info_checksum
    info_checksums[CompactIndex::CURRENT_FORMAT.checksum_column]
  end

  # Computes checksums for all active formats in a single DB query.
  def info_checksums
    rows = requirements_and_dependencies
    CompactIndex.active_formats.each_with_object({}) do |format, hash|
      versions = build_gem_versions(rows, format)
      hash[format.checksum_column] = Digest::MD5.hexdigest(CompactIndex.info(versions))
    end
  end

  def yanked_info_checksums
    info_checksums.transform_keys do |col|
      col.to_s.sub("info_checksum", "yanked_info_checksum").to_sym
    end
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
    compact_index_versions_for(date, CompactIndex::CURRENT_FORMAT)
  end

  def self.compact_index_versions_for(date, format)
    checksum_col = format.checksum_column
    yanked_col   = format.yanked_checksum_column

    query = ["(SELECT r.name, v.created_at as date, v.#{checksum_col} as info_checksum, v.number, v.platform
              FROM rubygems AS r, versions AS v
              WHERE v.rubygem_id = r.id AND
                    v.created_at > ?)
              UNION
              (SELECT r.name, v.yanked_at as date, v.#{yanked_col} as info_checksum, '-'||v.number, v.platform
              FROM rubygems AS r, versions AS v
              WHERE v.rubygem_id = r.id AND
                    v.indexed is false AND
                    v.yanked_at > ?)
              ORDER BY date, number, platform, name", date, date]

    map_gem_versions(execute_raw_sql(query).map { |v| [v["name"], [v]] })
  end

  def self.compact_index_public_versions(updated_at)
    compact_index_public_versions_for(updated_at, CompactIndex::CURRENT_FORMAT)
  end

  def self.compact_index_public_versions_for(updated_at, format)
    checksum_col = format.checksum_column
    yanked_col   = format.yanked_checksum_column

    query = ["SELECT r.name, v.indexed, COALESCE(v.yanked_at, v.created_at) as stamp,
                     v.sha256, COALESCE(v.#{yanked_col}, v.#{checksum_col}) as info_checksum,
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

  private_class_method :map_gem_versions, :execute_raw_sql

  private

  def build_gem_versions(rows, format)
    rows.map { |row| format.gem_version_from_row(row_to_hash(row)) }
  end

  def row_to_hash(row)
    *fields, dep_requirements, dep_names = row
    number, platform, sha256, info_checksum, ruby_version, rubygems_version, created_at = fields

    {
      number: number,
      platform: platform,
      checksum: Version._sha256_hex(sha256),
      info_checksum: info_checksum,
      ruby_version: ruby_version,
      rubygems_version: rubygems_version,
      created_at: created_at,
      dependencies: parse_deps(dep_requirements, dep_names)
    }
  end

  def parse_deps(dep_requirements, dep_names)
    return [] unless dep_requirements

    reqs = dep_requirements.split("@")
    names = dep_names.split(",")
    raise "BUG: different size of reqs and dep_names." unless reqs.size == names.size

    names.zip(reqs).filter_map do |name, req|
      CompactIndex::Dependency.new(name, req) unless name == "0"
    end
  end

  def requirements_and_dependencies
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
