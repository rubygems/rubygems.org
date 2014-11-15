namespace :gemcutter do
  namespace :index do
    desc "Update the index"
    task :update => :environment do
      require 'benchmark'
      Benchmark.bm do|b|
        b.report("update index") { Indexer.new.perform }
      end
    end
  end

  namespace :import do
    desc 'Bring the gems through the gemcutter process'
    task :process => :environment do
      gems = Dir[File.join(ARGV[1] || "#{Gem.path.first}/cache", "*.gem")].sort.reverse
      puts "Processing #{gems.size} gems..."
      gems.each do |path|
        puts "Processing #{path}"
        cutter = Pusher.new(nil, File.open(path))

        cutter.process
        unless cutter.code == 200
          puts cutter.message
        end
      end
    end
  end

  namespace :checksums do
    desc "Initialize missing checksums."
    task :init => :environment do
      versions = Version.without_sha256
      versions.each do |version|
        sha256 = version.recalculate_sha256
        version.sha256 = sha256
        version.save!
      end
    end

    desc "Check existing checksums."
    task :check => :environment do
      failed = false
      versions = Version.all
      versions.each do |version|
        actual_sha256 = version.recalculate_sha256
        if version.sha256 != actual_sha256
          puts "#{version.full_name}.gem has sha256 '#{actual_sha256}', but '#{version.sha256}' was expected."
          failed = true
        end
      end

      exit 1 if failed
    end
  end

  namespace :rubygems do
    desc "Update the download counts for all gems."
    task :update_download_counts => :environment do
      case_query = Rubygem.pluck(:name)
        .map { |name| "WHEN '#{name}' THEN #{$redis["downloads:rubygem:#{name}"].to_i}" }
        .join("\n            ")

      ActiveRecord::Base.connection.execute <<-SQL.strip_heredoc
        UPDATE rubygems
          SET downloads = CASE name
            #{case_query}
          END
      SQL
    end
  end

  desc "Move all but the last 2 days of version history to SQL"
  task :migrate_history => :environment do
    Download.copy_all_to_sql do |t,c,v|
      puts "#{c} of #{t}: #{v.full_name}"
    end
  end
end
