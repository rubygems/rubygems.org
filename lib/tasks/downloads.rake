namespace "gemcutter:downloads" do
  desc "Migrate from downloads table to redis"
  task :migrate => :environment do
    # create index "index_downloads_on_created_at_and_date" on downloads (version_id, date(created_at));
    # vacuum analyze downloads
    $redis.flushdb

    class Dl < ActiveRecord::Base
      set_table_name "downloads"
    end

    rubygems = Rubygem.all
    rubygems.each do |rubygem|
      print "> #{rubygem} "
      puts $redis[Download.key(rubygem)] = rubygem['downloads']
    end

    puts "*" * 80

    versions = Version.all(:include => :rubygem)
    vmap = {}
    versions.each do |version|
      print ">> #{Download.key(version)} "
      puts $redis[Download.key(version)] = version['downloads_count']
      vmap[version.id] = version
    end

    puts "*" * 80

    rows = ActiveRecord::Base.connection.select_rows "select count(version_id), version_id, date(created_at) from downloads group by version_id, date(created_at)"
    size = rows.size

    rows.each_with_index do |(count, version_id, date), index|
      version = vmap[version_id.to_i]
      puts ">>> #{index+1}/#{size} #{version.full_name} #{count} #{date}"

      $redis.hincrby Download.history_key(version), date, count
      $redis.hincrby Download.history_key(version.rubygem), date, count
    end
  end
end
