namespace :gemcutter do
  namespace :index do
    desc "Update the index"
    task :update => :environment do
      require 'benchmark'
      Benchmark.bm do|b|
        g = Pusher.new(nil, StringIO.new)
        b.report(" specs index") { g.upload("specs.4.8.gz", g.specs_index) }
        b.report("latest index") { g.upload("latest_specs.4.8.gz", g.latest_index) }
        b.report("   pre index") { g.upload("prerelease_specs.4.8.gz", g.prerelease_index) }
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

        cutter.pull_spec and cutter.find and cutter.save
      end
    end
  end

  namespace :rubygems do
    desc "update rubygems. run as: rake gemcutter:rubygems:update VERSION=[version number] RAILS_ENV=[staging|production] S3_KEY=[key] S3_SECRET=[secret]"
    task :update => :environment do
      version     = ENV["VERSION"]
      app_path    = Rails.root.join("config", "application.rb")
      old_content = app_path.read
      new_content = old_content.gsub(/RUBYGEMS_VERSION = "(.*)"/, %{RUBYGEMS_VERSION = "#{version}"})

      app_path.open("w") do |file|
        file.write new_content
      end

      updater = Indexer.new
      html    = Nokogiri.parse(open("http://rubyforge.org/frs/?group_id=126"))
      links   = html.css("a[href*='#{version}']").map { |n| n["href"] }

      if links.empty?
        abort "gem/tgz/zip for RubyGems #{version} hasn't been uploaded yet!"
      else
        links.each do |link|
          url = "http://rubyforge.org#{link}"

          puts "Uploading #{url}..."
          updater.directory.files.create({
            :body   => open(url).read,
            :key    => "rubygems/#{File.basename(url)}",
            :public => true
          })
        end
      end
    end

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
end
