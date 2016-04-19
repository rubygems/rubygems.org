namespace :gemcutter do
  namespace :index do
    desc "Update the index"
    task update: :environment do
      require 'benchmark'
      Benchmark.bm do |b|
        b.report("update index") { Indexer.new.perform }
      end
    end
  end

  namespace :import do
    desc 'Bring the gems through the gemcutter process'
    task process: :environment do
      gems = Dir[File.join(ARGV[1] || "#{Gem.path.first}/cache", "*.gem")].sort.reverse
      puts "Processing #{gems.size} gems..."
      gems.each do |path|
        puts "Processing #{path}"
        cutter = Pusher.new(nil, File.open(path))

        cutter.process
        puts cutter.message unless cutter.code == 200
      end
    end
  end

  namespace :checksums do
    desc "Initialize missing checksums."
    task init: :environment do
      without_sha256 = Version.where(sha256: nil)
      mod = ENV['shard']
      without_sha256.where("id % 4 = ?", mod.to_i) if mod

      total = without_sha256.count
      i = 0
      without_sha256.find_each do |version|
        version.recalculate_sha256!
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
        actual_sha256 = version.recalculate_sha256
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
      mod = ENV['shard']
      without_metadata = without_metadata.where("id % 4 = ?", mod.to_i) if mod

      total = without_metadata.count
      i = 0
      puts "Total: #{total}"
      without_metadata.find_each do |version|
        version.recalculate_metadata!
        i += 1
        print format("\r%.2f%% (%d/%d) complete", i.to_f / total * 100.0, i, total)
      end
      puts
      puts "Done."
    end
  end
end
