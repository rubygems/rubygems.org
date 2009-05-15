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

namespace :import do

  desc 'Download all of the gems in rubygems.txt'
  task :download do
    require 'curb'
    require 'active_support'
    url_queue = File.readlines("rubygems.txt").map { |g| g.strip }
    url_queue = url_queue[1..500]
    puts "Downloading #{url_queue.size} gems..."

    multi = Curl::Multi.new
    responses = {}
    url_queue.each do |url|
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
