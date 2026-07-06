# frozen_string_literal: true

class GemInfo
  include CompactIndexVersions

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
