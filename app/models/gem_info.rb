# frozen_string_literal: true

class GemInfo
  FORMATS = {
    v1: FormatV1.new,
    v2: FormatV2.new
  }.freeze

  def initialize(rubygem_name, cached: true)
    @rubygem_name = rubygem_name
    @cached = cached
  end

  def compact_index_info
    compact_index_info_for_format(:v1)
  end

  def compact_index_info_for_format(format_key)
    cached_compact_index_info(format_key)
  end

  def info_checksum
    checksum_for_format(:v1)
  end

  def checksum_for_format(format_key)
    fmt = FORMATS.fetch(format_key)
    checksum_for(requirements_and_dependencies, format: fmt)
  end

  def info_checksums
    rows = requirements_and_dependencies
    self.class.active_formats.each_with_object({}) do |(_, fmt), hash|
      hash[fmt.checksum_column] = checksum_for(rows, format: fmt)
    end
  end

  def self.active_formats
    FORMATS.select { |_, fmt| fmt.active? }
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
    compact_index_versions_for_format(date, :v1)
  end

  def self.compact_index_versions_for_format(date, format_key)
    fmt = FORMATS.fetch(format_key)
    checksum_column = fmt.checksum_column
    yanked_checksum_column = fmt.yanked_checksum_column

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

  def self.compact_index_public_versions(updated_at)
    compact_index_public_versions_for_format(updated_at, :v1)
  end

  def self.compact_index_public_versions_for_format(updated_at, format_key)
    fmt = FORMATS.fetch(format_key)
    checksum_column = fmt.checksum_column
    yanked_checksum_column = fmt.yanked_checksum_column

    query = ["SELECT r.name, v.indexed, COALESCE(v.yanked_at, v.created_at) as stamp,
                     v.sha256, COALESCE(v.#{yanked_checksum_column}, v.#{checksum_column}) as info_checksum,
                     v.number, v.platform
              FROM rubygems AS r, versions AS v
              WHERE v.rubygem_id = r.id AND
                    (v.created_at <= ? OR v.yanked_at <= ?)
              ORDER BY r.name, stamp, v.number, v.platform", updated_at, updated_at]

    versions_by_gem = execute_raw_sql(query).group_by { |v| v["name"] }
    versions_by_gem.each_value do |versions|
      info_checksum = versions.last["info_checksum"]
      versions.select! { |v| v["indexed"] == true }
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

  def cached_compact_index_info(format_key)
    fmt = FORMATS.fetch(format_key)
    cache_key = "#{fmt.cache_prefix}/#{@rubygem_name}"

    if @cached && (info = Rails.cache.read(cache_key))
      StatsD.increment "#{fmt.stats_key}.hit"
      info
    else
      StatsD.increment "#{fmt.stats_key}.miss"
      compact_index_info_for(requirements_and_dependencies, format: fmt).tap do |compact_index_info|
        Rails.cache.write(cache_key, compact_index_info)
      end
    end
  end

  def checksum_for(rows, format:)
    compact_index_info = CompactIndex.info(compact_index_info_for(rows, format:))
    Digest::MD5.hexdigest(compact_index_info)
  end

  def compact_index_info_for(rows, format:)
    rows.map { |row| format.gem_version_from_row(row_to_hash(row)) }
  end

  def row_to_hash(row)
    *fields, dep_requirements, dep_names = row
    number, platform, sha256, info_checksum, ruby_version, rubygems_version, _created_at = fields

    {
      number: number,
      platform: platform,
      checksum: Version._sha256_hex(sha256),
      info_checksum: info_checksum,
      ruby_version: ruby_version,
      rubygems_version: rubygems_version,
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
