# vim: syntax=Ruby
require 'rubygems'
require 'rake/rdoctask'
require 'rake/testtask'

task :gem do
	sh "gem build memcache-client.gemspec"
end

task :install => [:gem] do
	sh "sudo gem install memcache-client-*.gem"
end

task :clean do
	sh "rm -f memcache-client-*.gem"
end

task :publish => [:clean, :gem, :install] do
	require 'lib/memcache'
	sh "rubyforge add_release seattlerb memcache-client #{MemCache::VERSION} memcache-client-#{MemCache::VERSION}.gem"
end

Rake::RDocTask.new do |rd|
	rd.main = "README.rdoc"
	rd.rdoc_files.include("README.rdoc", "FAQ.rdoc", "History.rdoc", "lib/memcache.rb")
	rd.rdoc_dir = 'doc'
end

Rake::TestTask.new do |t|
  t.warning = true
end

task :default => :test

task :rcov do
  `rcov -Ilib test/*.rb`
end
