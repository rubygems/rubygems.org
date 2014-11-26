class AddVersionFullNameToRubygemNameInRedis < ActiveRecord::Migration
  def self.up
    Version.includes(:rubygem).find_each do |version|
      $redis.set("versions:#{version.full_name}", version.rubygem.name)
    end
  end

  def self.down
    $redis.keys('versions:*').each do |key|
      $redis.del(key)
    end
  end
end
