require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'spec/rake/spectask'

require 'tasks/rails'

desc 'Run the specs'
task :default => [:spec]

desc "Clean out files that aren't needed."
task :clean do
  system("git clean -dfx server/; git checkout server/")
end

Spec::Rake::SpecTask.new do |t|
  t.spec_opts = ['--format', 'progress', '--color', '--backtrace']
end

desc "Get the gem server up and running"
task :bootstrap do
  Rake::Task["clean"].execute
  ARGV[1] = "bench/old"
  Rake::Task["import:process"].execute
  Rake::Task["index:create"].execute
  ARGV[1] = "bench/new"
  Rake::Task["import:process"].execute
  Rake::Task["index:update"].execute
end

namespace :index do

  desc "Create the index"
  task :create do
    require 'app/cutter'
    require 'app/indexer'
    Gem::Cutter.indexer.generate_index
  end

  desc "Update the index"
  task :update do
    require 'app/cutter'
    require 'app/indexer'
    Gem::Cutter.indexer.update_index
  end

  desc "Benchmark gemcutter's indexer vs rubygems"
  task :bench do
    require 'benchmark'
    # Clean directory
    # Copy 100 gems in
    # Generate gem index
    # Copy 100 more gems in
    # Run update

    commands = <<EOF
git clean -dfxq server
cp -r bench/old/*.gem server/cache
gem generate_index -d server > /dev/null
cp -r bench/new/*.gem server/cache
EOF
    commands = commands.split("\n").join(";")

    code = <<EOF
Gem.configuration.verbose = false
i = Gem::Indexer.new('server', :build_legacy => false)
def i.say(message) end
i.update_index
EOF
    code = code.split("\n").join(";")
    rb = "require 'rubygems/indexer';" + code
    gc = "require './lib/rubygems/indexer';" + code

    Benchmark.bm(9) do |b|
      b.report("rubygems ") do
        system(commands)
        system(%{ruby -rubygems -e "#{rb}"})
      end
      b.report("gemcutter") do
        system(commands)
        system(%{ruby -rubygems -e "#{gc}"})
      end
    end
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
    url_queue.in_groups_of(100).each do |group|
      multi = Curl::Multi.new
      group.each do |url|
        easy = Curl::Easy.new(url) do |curl|
          curl.follow_location = true
          curl.on_success do |c|
            puts "Success for #{File.basename(url)} in #{c.total_time} seconds"
            begin
              File.open(File.join("cache", File.basename(url)), "wb") do |file|
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
  task :process do
    require 'rubygems/indexer'
    require 'app/app'

    gems = Dir[File.join(ARGV[1], "*.gem")]
    puts "Processing #{gems.size} gems..."
    gems.each do |gem|
      puts gem
      Gem::Cutter.new(File.open(gem)).process
    end
  end
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "gemcutter"
    gem.summary = "Simple and kickass gem hosting"
    gem.email = "nick@quaran.to"
    gem.homepage = "http://github.com/qrush/gemcutter"
    gem.authors = ["Nick Quaranto"]
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end
