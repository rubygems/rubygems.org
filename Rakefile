require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

require 'tasks/rails'

desc "Run all tests and features"
task :default => [:test, :features]

desc "Clean out files that aren't needed."
task :clean => :environment do
  system("git clean -dfx server/; git checkout server/")
  Rubygem.delete_all
  Version.delete_all
end

desc "Get the gem server up and running"
task :bootstrap => :environment do
  Rake::Task["clean"].execute
  Rake::Task["index:create"].execute
  ARGV[1] = "bench/old"
  Rake::Task["import:process"].execute
  ARGV[1] = "bench/new"
  Rake::Task["import:process"].execute
end

namespace :index do
  desc "Create the index"
  task :create => :environment do
    Gemcutter.indexer.generate_index
  end

  desc "Update the index"
  task :update => :environment do
    require 'gemcutter'
    Gemcutter.indexer.update_index
  end
end

namespace :import do
  desc 'Download all of the gems in rubygems.txt'
  task :download do
    require 'curb'
    require 'active_support'
    url_queue = File.readlines("rubygems.txt").map { |g| g.strip }
    puts "Downloading #{url_queue.size} gems..."
    FileUtils.mkdir("cache") unless File.exist?("cache")

    responses = {}
    url_queue.in_groups_of(25).each do |group|
      multi = Curl::Multi.new
      group.each do |url|
        next unless url
        path = File.join("cache", File.basename(url))
        if File.exists?(path)
          puts "Skipping #{File.basename(url)}"
          next
        end

        easy = Curl::Easy.new(url) do |curl|
          curl.follow_location = true
          curl.on_success do |c|
            puts "Success for #{File.basename(url)} in #{c.total_time} seconds"
            begin
              File.open(path, "wb") do |file|
                file.write c.body_str
              end
            rescue Exception => e
              puts "Problem saving: #{e}"
            end
          end
          curl.on_failure do |c|
            puts "Failure for #{File.basename(url)}: #{c.response_code}"
          end
        end
        multi.add(easy)
      end
      multi.perform
    end
  end

  desc 'Parse out rubygems'
  task :parse do
    require 'hpricot'
    doc = Hpricot(open("rubygems.html"))
    File.open("rubygems.txt", "w") do |file|
      (doc / "a")[1..-1].each do |gem|
        puts gem['href']
        file.write "http://gems.rubyforge.org/gems/#{gem['href']}\n"
      end
    end
  end

  desc 'Bring the gems through the gemcutter process'
  task :process => :environment do
    gems = Dir[File.join(ARGV[1], "*.gem")]
    puts "Processing #{gems.size} gems..."
    gems.each do |path|
      puts path
      spec = Rubygem.pull_spec(path)

      if spec.nil?
        puts "Bad gem: #{path}"
        next
      end

      rubygem = Rubygem.find_or_initialize_by_name(spec.name)
      rubygem.spec = spec
      rubygem.path = path
      rubygem.save
    end
  end
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "gemcutter"
    gem.summary = "Kickass gem hosting"
    gem.email = "nick@quaran.to"
    gem.homepage = "http://github.com/qrush/gemcutter"
    gem.authors = ["Nick Quaranto"]
    gem.files = FileList["lib/rubygems_plugin.rb", "lib/commands/*"]
    gem.test_files = []
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end
