namespace "gemcutter:downloads" do
  desc "Daily rollover and aggregation"
  task :rollover => :environment do
    Download.rollover
  end

  desc "Migrate from downloads table to redis"
  task :migrate => :environment do
    # create index "index_downloads_on_created_at_and_date" on downloads (version_id, date(created_at));
    # vacuum analyze downloads
    $redis.flushdb

    class Dl < ActiveRecord::Base
      set_table_name "downloads"
      include Pacecar
    end

    versions = Version.all(:include => :rubygem)
    vmap = {}
    versions.each do |version|
      print "> #{Download.key(version)} "
      puts $redis[Download.key(version)] = version['downloads_count']
      vmap[version.id] = version
    end

    puts "*" * 80

    rubygems = Rubygem.all
    rubygems.each do |rubygem|
      print ">> #{rubygem} "
      puts $redis[Download.key(rubygem)] = rubygem['downloads']
    end

    puts "*" * 80

    Dl.created_at_inside(Date.current.to_datetime, Date.current.to_datetime + 1.day).group_by(&:version_id).each do |version_id, downloads|
      name  = vmap[version_id].full_name
      count = downloads.size
      puts ">>> #{name}: #{count}"
      $redis.zincrby(Download::TODAY_KEY, count, name)
    end

    puts "*" * 80

    total = Dl.count
    size  = 10_000
    $redis.set Download::COUNT_KEY, total

    puts "Converting downloads..."
    Dl.find_in_batches(:select => "id, version_id, date(created_at)", :batch_size => size) do |batch|
      puts ">>>> #{total}"
      batch.group_by(&:version_id).each do |version_id, downloads|
        version = vmap[version_id]
        downloads.group_by { |dl| dl['date'] }.each do |date, dls|
          $redis.hincrby Download.history_key(version), date, dls.size
          $redis.hincrby Download.history_key(version.rubygem), date, dls.size
        end
      end
      total -= size
    end
  end
end
