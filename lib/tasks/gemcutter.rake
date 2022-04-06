require "tasks/helpers/gemcutter_tasks_helper"

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
    task process: :environment do
      gems = Dir[File.join(ARGV[1] || "#{Gem.path.first}/cache", "*.gem")].reverse
      puts "Processing #{gems.size} gems..."
      gems.each do |path|
        puts "Processing #{path}"
        cutter = Pusher.new(User.new, File.open(path))

        cutter.process
        puts cutter.message unless cutter.code == 200
      end
    end
  end

  namespace :checksums do
    desc "Initialize missing checksums."
    task init: :environment do
      without_sha256 = Version.where(sha256: nil)
      mod = ENV["shard"]
      without_sha256.where("id % 4 = ?", mod.to_i) if mod

      total = without_sha256.count
      i = 0
      without_sha256.find_each do |version|
        GemcutterTaskshelper.recalculate_sha256!(version)
        i += 1
        print format("\r%.2f%% (%d/%d) complete", i.to_f / total * 100.0, i, total)
      end
      puts
      puts "Done."
    end

    desc "Check existing checksums."
    task check: :environment do
      failed = false
      i = 0
      total = Version.count
      Version.find_each do |version|
        actual_sha256 = GemcutterTaskshelper.recalculate_sha256(version.full_name)
        if actual_sha256 && version.sha256 != actual_sha256
          puts "#{version.full_name}.gem has sha256 '#{actual_sha256}', " \
               "but '#{version.sha256}' was expected."
          failed = true
        end
        i += 1
        print format("\r%.2f%% (%d/%d) complete", i.to_f / total * 100.0, i, total)
      end
    end
  end

  namespace :metadata do
    desc "Backfill old gem versions with metadata."
    task backfill: :environment do
      without_metadata = Version.where("metadata = ''")
      mod = ENV["shard"]
      without_metadata = without_metadata.where("id % 4 = ?", mod.to_i) if mod

      total = without_metadata.count
      i = 0
      puts "Total: #{total}"
      without_metadata.find_each do |version|
        GemcutterTaskshelper.recalculate_metadata!(version)
        i += 1
        print format("\r%.2f%% (%d/%d) complete", i.to_f / total * 100.0, i, total)
      end
      puts
      puts "Done."
    end
  end

  namespace :required_ruby_version do
    desc "Backfill gem versions with rubygems_version."
    task backfill: :environment do
      ActiveRecord::Base.logger.level = 1 if Rails.env.development?

      without_required_ruby_version = Version.where("created_at < '2014-03-21' and required_ruby_version is null and indexed = true")
      mod = ENV["shard"]
      without_required_ruby_version = without_required_ruby_version.where("id % 4 = ?", mod.to_i) if mod

      total = without_required_ruby_version.count
      i = 0
      puts "Total: #{total}"
      without_required_ruby_version.find_each do |version|
        GemcutterTaskshelper.assign_required_ruby_version!(version)
        i += 1
        print format("\r%.2f%% (%d/%d) complete", i.to_f / total * 100.0, i, total)
      end
      puts
      puts "Done."
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
        Rails.logger.info "[gemcutter:gem_downloads:add_rubygems_record] added GemDownloads for rubygem_id: #{rubygem.id} with "\
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
