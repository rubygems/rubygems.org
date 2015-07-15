class AddVersionHashAndDepsListToRedis < ActiveRecord::Migration
  def self.up
    Redis.current.keys('versions:*').each do |key|
      Redis.current.del(key)
    end

    count = Version.count
    progress = 0
    Version.indexed.with_deps.find_each do |version|
      puts "#{progress += 1}/#{count}"
      next if version.rubygem.blank?

      Redis.current.hmset(Version.info_key(version.full_name), :name, version.rubygem.name, :number, version.number, :platform, version.platform)

      runtime_key = Dependency.runtime_key(version.full_name)
      version.dependencies.each do |dependency|
        Redis.current.lpush runtime_key, dependency if dependency.scope == "runtime"
      end

      Redis.current.lpush Rubygem.versions_key(version.rubygem.name), version.full_name
    end
  end

  def self.down
    [Redis.current.keys('v:*') + Redis.current.keys('rd:*') + Redis.current.keys('dd:*')].flatten.each do |key|
      Redis.current.del(key)
    end
  end
end
