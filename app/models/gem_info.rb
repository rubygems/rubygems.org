class GemInfo
  def initialize(rubygem_name)
    @rubygem_name = rubygem_name
  end

  def compact_index_info
    info = Rails.cache.read("info/#{@rubygem_name}")
    if info
      StatsD.increment "compact_index.memcached.info.hit"
      info
    else
      StatsD.increment "compact_index.memcached.info.miss"
      compute_compact_index_info.tap do |compact_index_info|
        Rails.cache.write("info/#{@rubygem_name}", compact_index_info)
      end
    end
  end

  def self.ordered_names
    names = Rails.cache.read('names')
    if names
      StatsD.increment "compact_index.memcached.names.hit"
    else
      StatsD.increment "compact_index.memcached.names.miss"
      names = Rubygem.order("name").pluck("name")
      Rails.cache.write('names', names)
    end
    names
  end

  def self.compact_index_versions(date)
    query = ["(SELECT r.name, v.created_at as date, v.info_checksum, v.number, v.platform
              FROM rubygems AS r, versions AS v
              WHERE v.rubygem_id = r.id AND
                    v.created_at > ?)
              UNION
              (SELECT r.name, v.yanked_at as date, v.yanked_info_checksum as info_checksum, '-'||v.number, v.platform
              FROM rubygems AS r, versions AS v
              WHERE v.rubygem_id = r.id AND
                    v.indexed is false AND
                    v.yanked_at > ?)
              ORDER BY date, number, platform, name", date, date]

    map_gem_versions execute_raw_sql(query).map { |v| [v['name'], [v]] }
  end

  def self.compact_index_public_versions
    query = ["SELECT r.name, v.indexed, COALESCE(v.yanked_at, v.created_at) as stamp,
                     v.sha256, COALESCE(v.yanked_info_checksum, v.info_checksum) as info_checksum,
                     v.number, v.platform
              FROM rubygems AS r, versions AS v
              WHERE v.rubygem_id = r.id
              ORDER BY r.name, stamp, v.number, v.platform"]

    versions_by_gem = execute_raw_sql(query).group_by { |v| v['name'] }
    versions_by_gem.each do |_, versions|
      info_checksum = versions.last['info_checksum']
      versions.select! { |v| v['indexed'] == 't'.freeze }
      # Set all versions' info_checksum to work around https://github.com/bundler/compact_index/pull/20
      versions.each { |v| v['info_checksum'] = info_checksum }
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
        CompactIndex::GemVersion.new(version['number'],
          version['platform'],
          version['sha256'],
          version['info_checksum'])
      end
      CompactIndex::Gem.new(gem_name, compact_index_versions)
    end
  end

  private_class_method :map_gem_versions, :execute_raw_sql

  private

  def compute_compact_index_info
    group_by_columns =
      "number, platform, sha256, info_checksum, required_ruby_version, required_rubygems_version, versions.created_at"
    dep_req_agg =
      "string_agg(dependencies.requirements, '@' order by rubygems_dependencies.name)"
    dep_name_agg =
      "string_agg(coalesce(rubygems_dependencies.name, '0'), ',' order by rubygems_dependencies.name) as dep_name"

    result = Rubygem.joins("LEFT JOIN versions ON versions.rubygem_id = rubygems.id
        LEFT JOIN dependencies ON dependencies.version_id = versions.id
        LEFT JOIN rubygems rubygems_dependencies
          ON rubygems_dependencies.id = dependencies.rubygem_id
          AND dependencies.scope = 'runtime'")
      .where("rubygems.name = ? and indexed = true", @rubygem_name)
      .group(group_by_columns)
      .order("versions.created_at, number, platform, dep_name")
      .pluck("#{group_by_columns}, #{dep_req_agg}, #{dep_name_agg}")

    result.map do |r|
      deps = []
      if r[7]
        reqs = r[7].split('@')
        dep_names = r[8].split(',')
        raise 'BUG: different size of reqs and dep_names.' unless reqs.size == dep_names.size
        dep_names.zip(reqs).each do |name, req|
          deps << CompactIndex::Dependency.new(name, req) unless name == '0'
        end
      end

      CompactIndex::GemVersion.new(r[0], r[1], Version._sha256_hex(r[2]), r[3], deps, r[4], r[5])
    end
  end
end
