namespace :gemcutter do
  namespace :index do
    desc "Update the index"
    task update: :environment do
      require "benchmark"
      Benchmark.bm do |b|
        b.report("update index") { Indexer.new.perform }
      end
    end
  end

  namespace :import do
    desc "Bring the gems through the gemcutter process"
    task :process, %i[gems_cache_path] => :environment do |_task, args|
      gems = Dir[File.join(args[:gems_cache_path] || "#{Gem.path.first}/cache", "*.gem")].reverse
      puts "Processing #{gems.size} gems..."
      gems.each do |path|
        puts "Processing #{path}"
        cutter = Pusher.new(User.new, File.open(path))

        cutter.process
        puts cutter.message unless cutter.code == 200
      end
    end
  end

  namespace :typo do
    desc "Add names to gem typo exception list\nUsage: rake gemcutter:typo:exception[<gem_name>,<info>]"
    task :exception, %i[name info] => %i[environment] do |_task, args|
      typo_exception = GemTypoException.new(name: args[:name], info: args[:info])
      if typo_exception.save
        puts "Added #{args[:name]} to gem typo exception"
      else
        puts "Error while adding typo exception: #{typo_exception.errors.full_messages}"
      end
    end
  end

  namespace :gem_downloads do
    desc "Add GemDownloads record for tracking total rubygems downloads"
    task add_rubygems_record: :environment do
      rubygems_without_total_downloads = Rubygem.where("id not in(select distinct(rubygem_id) from gem_downloads where version_id = 0)")

      total = rubygems_without_total_downloads.count
      processed = 0
      puts "Total: #{total}"
      rubygems_without_total_downloads.each do |rubygem|
        total_downloads = GemDownload.where(rubygem_id: rubygem.id).sum(:count)
        GemDownload.create!(count: total_downloads, rubygem_id: rubygem.id, version_id: 0)
        Rails.logger.info "[gemcutter:gem_downloads:add_rubygems_record] added GemDownloads for rubygem_id: #{rubygem.id} with " \
                          "total downloads: #{total_downloads}"
        processed += 1
        print format("\r%.2f%% (%d/%d) complete", processed.to_f / total * 100.0, processed, total)
      end
      puts
      puts "Done."
    end
  end

  namespace :versions do
    desc "Backfill canonical_number field of versions table"
    task backfill_canonical_number: :environment do
      versions = Version.where(canonical_number: nil).order(:created_at).all

      total = versions.count
      processed = 0
      puts "Total: #{total}"
      versions.find_each do |version|
        canonical_number = Gem::Version.new(version.number).canonical_segments.join(".")

        loop do
          conflicting_version = Version.find_by(canonical_number: canonical_number, rubygem_id: version.rubygem_id, platform: version.platform)
          break unless conflicting_version

          canonical_number += ".dedup"
        end

        version.update_attribute(:canonical_number, canonical_number)
        processed += 1
        print format("\r%.2f%% (%d/%d) complete", processed.to_f / total * 100.0, processed, total)
      end
      puts
      puts "Done."
    end
  end
end
