class Download
  COUNT_KEY     = "downloads"
  ALL_KEY       = "downloads:all"
  GEM_KEY       = "downloads:all:rubygem"

  def self.incr(name, full_name)
    today = Time.zone.today.to_s
    Redis.current.incr(COUNT_KEY)
    Redis.current.incr(rubygem_key(name)).tap do |count|
      Redis.current.zadd(GEM_KEY, count, name)
    end
    Redis.current.incr(version_key(full_name))
    Redis.current.zincrby(today_key, 1, full_name)
    Redis.current.zincrby(ALL_KEY, 1, full_name)
    Redis.current.hincrby(version_history_key(full_name), today, 1)
    Redis.current.hincrby(rubygem_history_key(name), today, 1)
  end

  def self.count
    Redis.current.get(COUNT_KEY).to_i
  rescue Redis::CannotConnectError
    nil
  end

  def self.today(*versions)
    versions.flatten.inject(0) do |sum, version|
      sum + Redis.current.zscore(today_key, version.full_name).to_i
    end
  end

  def self.for(what)
    Redis.current.get(key(what)).to_i
  end

  def self.for_rubygem(name)
    Redis.current.get(rubygem_key(name)).to_i
  end

  def self.for_version(full_name)
    Redis.current.get(version_key(full_name)).to_i
  end

  def self.most_downloaded_today(n = 5)
    items = Redis.current.zrevrange(today_key, 0, (n - 1), with_scores: true)
    items.collect do |full_name, downloads|
      version = Version.find_by_full_name(full_name)
      [version, downloads.to_i]
    end
  end

  def self.most_downloaded_all_time(n = 5)
    items = Redis.current.zrevrange(ALL_KEY, 0, (n - 1), with_scores: true)
    items.collect do |full_name, downloads|
      version = Version.find_by_full_name(full_name)
      [version, downloads.to_i]
    end
  end

  def self.most_downloaded_gems_all_time(n = 10)
    items = Redis.current.zrevrange(GEM_KEY, 0, (n - 1), with_scores: true)
    items.collect do |name, downloads|
      rubygem = Rubygem.find_by(name: name)
      [rubygem, downloads.to_i]
    end
  end

  def self.counts_by_day_for_versions(versions, days)
    dates = (days.days.ago.to_date...Time.zone.today).map(&:to_s)

    downloads = {}
    versions.each do |version|
      key = history_key(version)

      Redis.current.hmget(key, *dates).zip(dates).each do |count, date|
        if count
          count = count.to_i
        else
          vh = VersionHistory.find_by(version_id: version.id, day: date)

          count = vh ? vh.count : 0
        end

        downloads["#{version.id}-#{date}"] = count
      end
      downloads["#{version.id}-#{Time.zone.today}"] = today(version)
    end

    downloads
  end

  def self.counts_by_day_for_version_in_date_range(version, start, stop)
    downloads = ActiveSupport::OrderedHash.new

    dates = (start..stop).map(&:to_s)

    Redis.current.hmget(history_key(version), *dates).zip(dates).each do |count, date|
      if count
        count = count.to_i
      else
        vh = VersionHistory.find_by(version_id: version.id, day: date)

        if vh
          count = vh.count
        else
          count = 0
        end
      end

      downloads[date] = count
    end

    downloads["#{Time.zone.today}"] = today(version) if stop == Time.zone.today

    downloads
  end

  def self.copy_to_sql(version, date)
    count = Redis.current.hget(history_key(version), date)
    version_history = VersionHistory.for(version, date)
    if version_history
      version_history.count = count
      version_history.save
    else
      VersionHistory.make(version, date, count)
    end
  end

  def self.copy_all_to_sql
    i = 0
    count = 0
    versions = Version.all
    total = versions.size

    VersionHistory.transaction do
      versions.each do |ver|
        i += 1
        yield total, i, ver if block_given?

        dates = migrate_to_sql ver, false
        count += 1 unless dates.empty?
      end
    end

    count
  end

  def self.migrate_to_sql(version, remove = true)
    key = history_key version

    dates = Redis.current.hkeys(key)

    back = 1.day.ago.to_date

    dates.delete_if { |e| Date.parse(e) >= back }

    dates.each do |d|
      copy_to_sql version, d
      Redis.current.hdel key, d if remove
    end

    dates
  end

  def self.migrate_all_to_sql
    i = 0
    count = 0
    versions = Version.all
    total = versions.size

    versions.each do |ver|
      i += 1
      yield total, i, ver if block_given?

      dates = migrate_to_sql ver
      count += 1 unless dates.empty?
    end

    count
  end

  def self.counts_by_day_for_version(version)
    counts_by_day_for_version_in_date_range(version, Time.zone.today - 89.days, Time.zone.today)
  end

  def self.key(what)
    case what
    when Version
      version_key(what.full_name)
    when Rubygem
      rubygem_key(what.name)
    else
      fail TypeError, "Unknown type for key - #{what.class}"
    end
  end

  def self.history_key(what)
    case what
    when Version
      version_history_key(what.full_name)
    when Rubygem
      rubygem_history_key(what.name)
    else
      fail TypeError, "Unknown type for history_key - #{what.class}"
    end
  end

  def self.cardinality
    Redis.current.zcard(today_key)
  end

  def self.rank(version)
    rank = Redis.current.zrevrank(today_key, version.full_name)
    rank ? rank + 1 : 0
  end

  def self.cleanup_today_keys
    Redis.current.del(*today_keys)
  end

  def self.today_keys
    today_keys = Redis.current.keys("downloads:today:*")
    today_keys.delete(today_key)
    today_keys
  end

  def self.today_key(date_string = Time.zone.today)
    "downloads:today:#{date_string}"
  end

  def self.version_history_key(full_name)
    "downloads:version_history:#{full_name}"
  end

  def self.rubygem_history_key(name)
    "downloads:rubygem_history:#{name}"
  end

  def self.version_key(full_name)
    "downloads:version:#{full_name}"
  end

  def self.rubygem_key(name)
    "downloads:rubygem:#{name}"
  end
end
