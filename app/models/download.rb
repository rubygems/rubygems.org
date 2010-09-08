class Download
  COUNT_KEY     = "downloads"
  TODAY_KEY     = "downloads:today"
  YESTERDAY_KEY = "downloads:yesterday"
  DOWNLOADED_KEY = "downloaded"

  def self.incr(name, full_name)
    $redis.incr(COUNT_KEY)
    $redis.incr("downloads:rubygem:#{name}")
    $redis.incr("downloads:version:#{full_name}")
    $redis.zincrby(TODAY_KEY, 1, full_name)
    $redis.lpush(DOWNLOADED_KEY, name)
    $redis.ltrim(DOWNLOADED_KEY, 0, 2)
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

  def self.most_downloaded_today
    items = $redis.zrevrange(TODAY_KEY, 0, 4, :with_scores => true)
    items.in_groups_of(2).collect do |full_name, downloads|
      version = Version.find_by_full_name(full_name)

      [version, downloads.to_i]
    end
  end

  def self.latest
    $redis.lrange(DOWNLOADED_KEY,0,-1)
  end

  def self.key(what)
    case what
    when Version
      "downloads:version:#{what.full_name}"
    when Rubygem
      "downloads:rubygem:#{what.name}"
    end
  end

  def self.history_key(what)
    case what
    when Version
      "downloads:version_history:#{what.full_name}"
    when Rubygem
      "downloads:rubygem_history:#{what.name}"
    end
  end

  def self.rollover
    $redis.rename TODAY_KEY, YESTERDAY_KEY

    yesterday = 1.day.ago.to_date.to_s
    versions  = Version.includes(:rubygem).inject({}) do |hash, v|
      hash[v.full_name] = v
      hash
    end

    downloads = Hash[*$redis.zrange(YESTERDAY_KEY, 0, -1, :with_scores => true)]
    downloads.each do |key, score|
      version = versions[key]
      $redis.hincrby history_key(version), yesterday, score.to_i
      $redis.hincrby history_key(version.rubygem), yesterday, score.to_i
      version.rubygem.increment! :downloads, score.to_i
    end
  end
end
