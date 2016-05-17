class GemDependent
  attr_reader :gem_names

  def initialize(gem_names)
    @gem_information = {}
    @gem_names = gem_names
  end

  def fetch_dependencies
    dependencies = []
    @gem_names.each { |g| @gem_information[g] = "deps/v1/#{g}" }

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
    gem_record = Rubygem.includes(:versions).find_by_name!(gem_name)
    gem_record.versions.includes(:dependencies).sort_by(&:number).reverse_each.map do |version|
      version_deps = version.dependencies.select { |d| d.scope == 'runtime' }

      {
        name: gem_name,
        number: version.number,
        platform: version.platform,
        dependencies: version_deps.map { |d| [d.name, d.requirements] }
      }
    end
  end

  # Returns a Hash of the gem's cache key, and its cached dependencies
  def memcached_gem_info
    @memcached_gem_info ||= Rails.cache.read_multi(*@gem_information.values)
  end
end
