namespace :gemcutter do
  desc "Reorder gem versions"
  task :reorder_versions => :environment do
    current = 1
    count   = Rubygem.count
    Rubygem.find_each do |rubygem|
      puts "Reordering #{current}/#{count} - #{rubygem.name}"
      rubygem.reorder_versions
      current += 1
    end
  end

  desc "fix full names"
  task :fix_full_names => :environment do
    Version.without_any_callbacks do
      def Version.run_callbacks; "no idea why this is necessary"; end
      Version.all(:include => :rubygem).each do |version|
        version.full_nameify!
      end
    end
  end

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

    desc "benchmark index creation"
    task :benchmark => :environment do
      require 'benchmark'
      puts "Total versions: #{Version.count}"
      Benchmark.bm do|b|
        g = Pusher.new(nil, StringIO.new)
        b.report(" specs index") { g.stringify(g.specs_index) }
        b.report("latest index") { g.stringify(g.latest_index) }
        b.report("   pre index") { g.stringify(g.prerelease_index) }
      end
    end

    desc "fix the index"
    task :reprocess => :environment do
      index = Gem::SourceIndex.new

      Rubygem.with_versions.each do |rubygem|
        rubygem.versions.each do |version|

          install = "#{rubygem.name}-#{version.number}"
          quick_path = "quick/Marshal.#{Gem.marshal_version}/#{install}.gemspec.rz"

          if VaultObject.exists?(quick_path)
            puts ">> Processing #{install}"
            begin
              spec = Marshal.load(Gem.inflate(VaultObject.value(quick_path)))
            rescue Exception => e
              puts ">> EXCEPTION: #{e}"
              version.update_attribute(:indexed, false)
            end

            version.description = spec.description
            version.summary = spec.summary
            version.number = spec.version.to_s

            platform = spec.original_platform
            platform = Gem::Platform::RUBY if platform.nil? or platform.empty?
            version.platform = platform
            version.save

            spec.development_dependencies.each { |dep| version.dependencies.create_from_gem_dependency!(dep) }

            index.add_spec(spec)
          else
            puts ">> BAD GEM: #{install}"
            version.update_attribute(:indexed, false)
          end
        end
      end

      puts ">> ding, gems are done!"
      File.open("/tmp/index", "wb") { |f| f.write Marshal.dump(index) }
    end
  end

  namespace :import do
    desc 'Make sure all of the gems are on S3'
    task :verify => :environment do
      return unless Rails.env.production?
      Version.all.each do |version|
        path = "#{version.rubygem.name}-#{version.number}.gem"
        gem_path = "gems/#{path}"
        spec_path = "quick/Marshal.4.8/#{path}spec.rz"

        puts gem_path unless VaultObject.exists?(gem_path)
        puts spec_path unless VaultObject.exists?(spec_path)
      end
    end

    desc 'Upload gems to s3 like a boss'
    task :upload => :environment do
      return unless Rails.env.production?
      Version.all.each do |version|
        local_path = File.join(ARGV[1], "#{version.rubygem.name}-#{version.number}.gem")
        if File.exists?(local_path)
          puts "Processing #{local_path}"
          begin
            cutter = Pusher.new(nil, StringIO.new(File.open(local_path).read))
            cutter.pull_spec
            cutter.write
          rescue Exception => e
            puts "Problem uploading #{local_path}: #{e}"
          end
        else
          puts "Couldn't find #{local_path}"
        end
      end
    end

    desc 'Bring the gems through the gemcutter process'
    task :process => :environment do
      gems = Dir[File.join(ARGV[1], "*.gem")].sort.reverse
      puts "Processing #{gems.size} gems..."
      gems.each do |path|
        puts "Processing #{path}"
        cutter = Pusher.new(nil, StringIO.new(File.open(path).read))

        cutter.pull_spec and cutter.find and cutter.save
      end
    end

    desc 'Just create the index and save the gems in the db'
    task :indexify => :environment do
      gems = Dir[File.join(ARGV[1], "*.gem")].sort.reverse
      puts "Processing #{gems.size} gems..."
      source_index = Gem::SourceIndex.new

      gems.each do |path|
        puts "Processing #{path}"
        cutter = Pusher.new(nil, StringIO.new(File.open(path).read))

        begin
          cutter.pull_spec and cutter.find and cutter.build
          spec_path = File.join(ARGV[1], "#{cutter.rubygem.name}-#{cutter.rubygem.versions.last.to_s}.gem")

          if path == spec_path
            cutter.rubygem.save
            spec = cutter.spec
            Pusher.indexer.abbreviate spec
            Pusher.indexer.sanitize spec
            source_index.add_spec(spec, spec.original_name)
          else
            puts "Processed path (#{spec_path}) did not match: #{path}"
          end
        rescue Exception => e
          puts "Bad gem: #{e}"
        end
      end

      File.open(Pusher.server_path("source_index"), "wb") do |f|
        f.write Gem.deflate(Marshal.dump(source_index))
      end

      Pusher.indexer.update_index(source_index)
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

      class Updater
        include Vault
      end

      updater = Updater.new
      html    = Nokogiri.parse(open("http://rubyforge.org/frs/?group_id=126"))
      links   = html.css("a[href*='#{version}']").map { |n| n["href"] }
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
end
