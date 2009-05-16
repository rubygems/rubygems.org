require 'rake'
require 'rake/testtask'
require 'spec/rake/spectask'

desc 'Run the specs and tests for rubygems'
task :default => [:spec, :test_rubygems]

Spec::Rake::SpecTask.new do |t|
  t.spec_opts = ['--format', 'progress', '--color', '--backtrace']
end

Rake::TestTask.new(:test_rubygems) do |t|
  t.libs << 'lib/rubygems'
  t.pattern = 'spec/rubygems/test_*.rb'
  t.verbose = false
end

namespace :indexer do
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

    responses = {}
    url_queue.in_groups_of(100).each do |group|
      multi = Curl::Multi.new
      group.each do |url|
        easy = Curl::Easy.new(url) do |curl|
          curl.follow_location = true
          curl.on_success do |c|
            puts "Success for #{File.basename(url)} in #{c.total_time} seconds"
            File.open(File.join("server", "cache", File.basename(url)), "wb") do |file|
              file.write c.body_str
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
