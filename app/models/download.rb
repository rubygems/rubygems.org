class Download
  COUNT_KEY     = "downloads"
  TODAY_KEY     = "downloads:today"
  YESTERDAY_KEY = "downloads:yesterday"

  def self.incr(name, full_name)
    $redis.incr(COUNT_KEY)
    $redis.incr(rubygem_key(name))
    $redis.incr(version_key(full_name))
    $redis.zincrby(TODAY_KEY, 1, full_name)
  end

  def self.count
    $redis.get(COUNT_KEY).to_i
  end

  def self.today(*versions)
    versions.flatten.inject(0) do |sum, version|
      sum + $redis.zscore(TODAY_KEY, version.full_name).to_i
    end
  end

  def self.for(what)
    $redis.get(key(what)).to_i
  end

  def self.for_rubygem(name)
    $redis.get(rubygem_key(name)).to_i
  end

  def self.for_version(full_name)
    $redis.get(version_key(full_name)).to_i
  end

  def self.most_downloaded_today
    items = $redis.zrevrange(TODAY_KEY, 0, 4, :with_scores => true)
    items.in_groups_of(2).collect do |full_name, downloads|
      version = Version.find_by_full_name(full_name)

      [version, downloads.to_i]
    end
  end

  def self.counts_by_day_for_versions(versions, days)
    dates = (days.days.ago.to_date...Date.current).map &:to_s

    versions.inject({}) do |downloads, version|
      $redis.hmget(self.history_key(version), *dates).each_with_index do |count, idx|
        downloads["#{version.id}-#{dates[idx]}"] = count.to_i
      end
      downloads["#{version.id}-#{Date.current}"] = self.today(version)
      downloads
    end
  end

  def self.key(what)
    case what
    when Version
      version_key(what.full_name)
    when Rubygem
      rubygem_key(what.name)
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
      if version = versions[key]
        $redis.hincrby history_key(version), yesterday, score.to_i
        $redis.hincrby history_key(version.rubygem), yesterday, score.to_i
        version.rubygem.increment! :downloads, score.to_i
      end
    end
  end

  def self.cardinality
    $redis.zcard(TODAY_KEY)
  end

  def self.rank(version)
    if rank = $redis.zrevrank(TODAY_KEY, version.full_name)
      rank + 1
    else
      0
    end
  end

  def self.highest_rank(versions)
    ranks = versions.map { |version| Download.rank(version) }.reject(&:zero?)
    if ranks.empty?
      0
    else
      ranks.min
    end
  end

  def self.version_key(full_name)
    "downloads:version:#{full_name}"
  end

  def self.rubygem_key(name)
    "downloads:rubygem:#{name}"
  end
end
