class Download < ActiveRecord::Base

  COUNT_KEY = "downloads"
  TODAY_KEY = "downloads:today"

  def self.incr(version)
    $redis.incr(COUNT_KEY)
    $redis.incr(key(version.rubygem))
    $redis.incr(key(version))
    $redis.zincrby(TODAY_KEY, 1, version.full_name)
  end

  def self.count
    $redis[COUNT_KEY].to_i
  end

  def self.today(version)
    $redis.zscore(TODAY_KEY, version.full_name).to_i
  end

  def self.for(what)
    $redis[key(what)].to_i
  end

  def self.key(what)
    case what
    when Version
      "downloads:version:#{what.full_name}"
    when Rubygem
      "downloads:rubygem:#{what.name}"
    end
  end
end
