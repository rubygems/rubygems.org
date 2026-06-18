# frozen_string_literal: true

class GemInfo
  CURRENT_VERSION = 2

  VERSIONS = {
    2 => { cache_prefix: "info_v2", stats_prefix: "compact_index.memcached.info_v2", klass: CompactIndex::GemVersionV2,
           checksum_column: "info_checksum_v2", yanked_checksum_column: "yanked_info_checksum_v2" }
  }.freeze

  def initialize(rubygem_name, cached: true)
    @rubygem_name = rubygem_name
    @cached = cached
  end

  def compact_index_info(version: CURRENT_VERSION)
    config = VERSIONS.fetch(version)
    cache_key = "#{config[:cache_prefix]}/#{@rubygem_name}"
    stats_key = config[:stats_prefix]

    if @cached && (info = read_cache(cache_key))
      StatsD.increment "#{stats_key}.hit"
      info
    else
      StatsD.increment "#{stats_key}.miss"
      compute_compact_index_info(version:).tap do |result|
        Rails.cache.write(cache_key, result)
      end
    end
  end

  def info_checksum(version: CURRENT_VERSION)
    compact_index_info = CompactIndex.info(compute_compact_index_info(version:))
    Digest::MD5.hexdigest(compact_index_info)
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

  def self.compact_index_versions(date, version: CURRENT_VERSION)
    config = VERSIONS.fetch(version)
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

  def self.compact_index_public_versions(updated_at, version: CURRENT_VERSION)
    config = VERSIONS.fetch(version)
    checksum_column = config[:checksum_column]
    yanked_checksum_column = config[:yanked_checksum_column]

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

  DEPENDENCY_NAMES_INDEX = 8

  DEPENDENCY_REQUIREMENTS_INDEX = 7

  # Marshal.load of pre-deploy cache entries fails when GemVersion grows a Struct field.
  def read_cache(cache_key)
    Rails.cache.read(cache_key)
  rescue TypeError
    nil
  end

  def compute_compact_index_info(version:)
    requirements_and_dependencies(version:).map do |row|
      dependencies = []
      if row[DEPENDENCY_REQUIREMENTS_INDEX]
        reqs = row[DEPENDENCY_REQUIREMENTS_INDEX].split("@")
        dep_names = row[DEPENDENCY_NAMES_INDEX].split(",")
        raise "BUG: different size of reqs and dep_names." unless reqs.size == dep_names.size
        dep_names.zip(reqs).each do |name, req|
          dependencies << CompactIndex::Dependency.new(name, req) unless name == "0"
        end
      end

      number, platform, checksum, info_checksum, ruby_version, rubygems_version, created_at, = row
      version_class = VERSIONS.dig(version, :klass)
      checksum = Version._sha256_hex(checksum)
      created_at = created_at&.utc&.iso8601
      args = { number:, platform:, checksum:, info_checksum:, dependencies:, ruby_version:, rubygems_version:, created_at: }
      args = args.slice(*version_class.members)
      version_class.new(**args)
    end
  end

  def requirements_and_dependencies(version:)
    @requirements_and_dependencies ||= {}
    @requirements_and_dependencies[version] ||= fetch_requirements_and_dependencies(version:)
  end

  def fetch_requirements_and_dependencies(version:)
    checksum_column = VERSIONS.fetch(version).fetch(:checksum_column)
    group_by_columns = [
      "number", "platform", "sha256", checksum_column,
      "required_ruby_version", "required_rubygems_version", "versions.created_at"
    ]

    dep_req_agg = "string_agg(dependencies.requirements, '@' ORDER BY rubygems_dependencies.name, dependencies.id)"

    dep_name_agg = "string_agg(coalesce(rubygems_dependencies.name, '0'), ',' ORDER BY rubygems_dependencies.name) AS dep_name"

    Rubygem.joins("LEFT JOIN versions ON versions.rubygem_id = rubygems.id
        LEFT JOIN dependencies ON dependencies.version_id = versions.id
        LEFT JOIN rubygems rubygems_dependencies
          ON rubygems_dependencies.id = dependencies.rubygem_id
          AND dependencies.scope = 'runtime'")
      .where("rubygems.name = ? AND versions.indexed = true", @rubygem_name)
      .group(*group_by_columns)
      .order(Arel.sql("versions.created_at, number, platform, dep_name"))
      .pluck(*group_by_columns, Arel.sql(dep_req_agg), Arel.sql(dep_name_agg))
  end
end
