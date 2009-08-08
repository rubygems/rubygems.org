# -*- encoding: utf-8 -*-
begin
  require 'jeweler'
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
  exit 1
end

Jeweler::Tasks.new do |s|
  s.name     = "delayed_job"
  s.summary  = "Database-backed asynchronous priority queue system -- Extracted from Shopify"
  s.email    = "tobi@leetsoft.com"
  s.homepage = "http://github.com/tobi/delayed_job/tree/master"
  s.description = "Delayed_job (or DJ) encapsulates the common pattern of asynchronously executing longer tasks in the background. It is a direct extraction from Shopify where the job table is responsible for a multitude of core tasks."
  s.authors  = ["Tobias Lütke"]
  
  s.has_rdoc = true
  s.rdoc_options = ["--main", "README.textile", "--inline-source", "--line-numbers"]
  s.extra_rdoc_files = ["README.textile"]
  
  s.test_files = Dir['spec/**/*']
end
