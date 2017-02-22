class GemDependent
  extend StatsD::Instrument
  DepKey = Struct.new(:name, :number, :platform, :required_ruby_version, :required_rubygems_version, :info_checksum)

  attr_reader :gem_names

  def initialize(gem_names)
    @gem_information = {}
    @gem_names = gem_names
  end

  def fetch_dependencies
    @gem_names.each { |g| @gem_information[g] = gem_cache_key(g) }

    @gem_information.flat_map do |gem_name, cache_key|
      if (dependency = memcached_gem_info[cache_key])
        # Fetch the gem's dependencies from the cache
        StatsD.increment statsd_hit_key
      else
        # Fetch the gem's dependencies from the database
        StatsD.increment statsd_miss_key
        dependency = fetch_dependency_from_db(gem_name)
        Rails.cache.write(cache_key, dependency)
        memcached_gem_info[cache_key] = dependency
      end

      dependency
    end
  end

  alias to_a fetch_dependencies

  private

  def gem_cache_key(g)
    "deps/v1/#{g}"
  end

  def statsd_hit_key
    'gem_dependent.memcached.hit'
  end

  def statsd_miss_key
    'gem_dependent.memcached.miss'
  end

  def fetch_dependency_from_db(gem_name)
    sanitize_sql = ActiveRecord::Base.send(:sanitize_sql_array, sql_query(gem_name))
    dataset = ActiveRecord::Base.connection.execute(sanitize_sql)

    deps = dataset.group_by do |row|
      DepKey.new(row['name'], row['number'], row['platform'], row['required_ruby_version'], row['required_rubygems_version'], row['info_checksum'])
    end

    deps.map do |dep_key, gem_deps|
      dependencies = gem_deps.select { |row| row['dep_name'] }.map { |row|
        [row['dep_name'], row['requirements']]
      }

      build_gem_payload dep_key, dependencies
    end
  end
  statsd_measure :fetch_dependency_from_db, 'gem_dependent.fetch_dependency_from_db'

  def build_gem_payload(dep_key, dependencies)
    {
      name:                  dep_key.name,
      number:                dep_key.number,
      platform:              dep_key.platform,
      dependencies:          dependencies
    }
  end

  def sql_query(gem_name)
    ["SELECT rv.name, rv.number, rv.platform, rv.info_checksum, rv.required_ruby_version, rv.required_rubygems_version, d.requirements, for_dep_name.name dep_name
      FROM
        (SELECT r.name, v.number, v.platform, v.info_checksum, v.required_ruby_version, v.required_rubygems_version, v.id AS version_id
        FROM rubygems AS r, versions AS v
        WHERE v.rubygem_id = r.id
          AND v.indexed is true AND r.name = ?) AS rv
        LEFT JOIN dependencies AS d ON
          d.version_id = rv.version_id
        LEFT JOIN rubygems AS for_dep_name ON
          d.rubygem_id = for_dep_name.id
          AND d.scope = 'runtime'", gem_name]
  end

  # Returns a Hash of the gem's cache key, and its cached dependencies
  def memcached_gem_info
    @memcached_gem_info ||= Rails.cache.read_multi(*@gem_information.values)
  end
end
