class GemDependent
  extend StatsD::Instrument
  DepKey = Struct.new(:name, :number, :platform)

  attr_reader :gem_names

  def initialize(gem_names, force = false)
    @gem_information = {}
    @gem_names = gem_names
    @force = force
  end

  def fetch_dependencies
    dependencies = []
    @gem_names.select { |g| @force || !Patterns::GEM_NAME_BLACKLIST.include?(g) }.each { |g| @gem_information[g] = "deps/v1/#{g}" }

    @gem_information.each do |gem_name, cache_key|
      if (dependency = memcached_gem_info[cache_key])
        # Fetch the gem's dependencies from the cache
        StatsD.increment 'gem_dependent.memcached.hit'
        dependencies << dependency
      else
        # Fetch the gem's dependencies from the database
        StatsD.increment 'gem_dependent.memcached.miss'
        result = fetch_dependency_from_db(gem_name)
        Rails.cache.write(cache_key, result)
        memcached_gem_info[cache_key] = result
        dependencies << result
      end
    end

    dependencies.flatten
  end

  alias to_a fetch_dependencies

  private

  def fetch_dependency_from_db(gem_name)
    sanitize_sql = ActiveRecord::Base.send(:sanitize_sql_array, sql_query(gem_name))
    dataset = ActiveRecord::Base.connection.execute(sanitize_sql)
    deps = {}

    dataset.each do |row|
      key = DepKey.new(row['name'], row['number'], row['platform'])
      deps[key] = [] unless deps[key]
      deps[key] << [row['dep_name'], row['requirements']] if row['dep_name']
    end

    deps.map do |dep_key, gem_deps|
      {
        name:                  dep_key.name,
        number:                dep_key.number,
        platform:              dep_key.platform,
        dependencies:          gem_deps
      }
    end
  end
  statsd_measure :fetch_dependency_from_db, 'gem_dependent.fetch_dependency_from_db'

  def sql_query(gem_name)
    ["SELECT rv.name, rv.number, rv.platform, d.requirements, for_dep_name.name dep_name
      FROM
        (SELECT r.name, v.number, v.platform, v.id AS version_id
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
