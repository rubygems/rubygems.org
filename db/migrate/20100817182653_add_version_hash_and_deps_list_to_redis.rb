class AddVersionHashAndDepsListToRedis < ActiveRecord::Migration
  def self.up
    $redis.keys('versions:*').each do |key|
      $redis.del(key)
    end

    count = Version.count
    progress = 0
    Version.indexed.with_deps.find_each do |version|
      puts "#{progress += 1}/#{count}"
      next if version.rubygem.blank?

      $redis.hmset(Version.info_key(version.full_name),
                   :name, version.rubygem.name,
                   :number, version.number,
                   :platform, version.platform)

      runtime_key = Dependency.runtime_key(version.full_name)
      version.dependencies.each do |dependency|
        $redis.lpush runtime_key, dependency if dependency.scope == "runtime"
      end

      $redis.lpush Rubygem.versions_key(version.rubygem.name), version.full_name
    end
  end

  def self.down
    [$redis.keys('v:*') + $redis.keys('rd:*') + $redis.keys('dd:*')].flatten.each do |key|
      $redis.del(key)
    end
  end
end
