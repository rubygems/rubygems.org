require 'rake/clean'

task :default => :test

CLEAN.include %w[coverage/ doc/api tags]
CLOBBER.include %w[dist]

# load gemspec like github's gem builder to surface any SAFE issues.
Thread.new do
  require 'rubygems/specification'
  $spec = eval("$SAFE=3\n#{File.read('rack-cache.gemspec')}")
end.join

# SPECS =====================================================================

desc 'Run specs with story style output'
task :spec do
  sh 'specrb --specdox -Ilib:test test/*_test.rb'
end

desc 'Run specs with unit test style output'
task :test => FileList['test/*_test.rb'] do |t|
  suite = t.prerequisites
  sh "specrb -Ilib:test #{suite.join(' ')}", :verbose => false
end

desc 'Generate test coverage report'
task :rcov do
  sh "rcov -Ilib:test test/*_test.rb"
end

# DOC =======================================================================
desc 'Build all documentation'
task :doc => %w[doc:api doc:markdown]

# requires the hanna gem:
#   gem install mislav-hanna --source=http://gems.github.com
desc 'Build API documentation (doc/api)'
task 'doc:api' => 'doc/api/index.html' 
file 'doc/api/index.html' => FileList['lib/**/*.rb'] do |f|
  rm_rf 'doc/api'
  sh((<<-SH).gsub(/[\s\n]+/, ' ').strip)
  hanna
    --op doc/api
    --promiscuous
    --charset utf8
    --fmt html
    --inline-source
    --line-numbers
    --accessor option_accessor=RW
    --main Rack::Cache
    --title 'Rack::Cache API Documentation'
    #{f.prerequisites.join(' ')}
  SH
end
CLEAN.include 'doc/api'

desc 'Build markdown documentation files'
task 'doc:markdown'
FileList['doc/*.markdown'].each do |source|
  dest = "doc/#{File.basename(source, '.markdown')}.html"
  file dest => [source, 'doc/layout.html.erb'] do |f|
    puts "markdown: #{source} -> #{dest}" if verbose
    require 'erb' unless defined? ERB
    require 'rdiscount' unless defined? RDiscount
    template = File.read(source)
    content = Markdown.new(ERB.new(template, 0, "%<>").result(binding), :smart).to_html
    title = content.match("<h1>(.*)</h1>")[1] rescue ''
    layout = ERB.new(File.read("doc/layout.html.erb"), 0, "%<>")
    output = layout.result(binding)
    File.open(dest, 'w') { |io| io.write(output) }
  end
  task 'doc:markdown' => dest
  CLEAN.include dest
end

desc 'Publish documentation'
task 'doc:publish' => :doc do
  sh 'rsync -avz doc/ gus@tomayko.com:/src/rack-cache'
end

desc 'Start the documentation development server (requires thin)'
task 'doc:server' do
  sh 'cd doc && thin --rackup server.ru --port 3035 start'
end

# PACKAGING =================================================================

def package(ext='')
  "dist/rack-cache-#{$spec.version}" + ext
end

desc 'Build packages'
task :package => %w[.gem .tar.gz].map {|e| package(e)}

desc 'Build and install as local gem'
task :install => package('.gem') do
  sh "gem install #{package('.gem')}"
end

directory 'dist/'

file package('.gem') => %w[dist/ rack-cache.gemspec] + $spec.files do |f|
  sh "gem build rack-cache.gemspec"
  mv File.basename(f.name), f.name
end

file package('.tar.gz') => %w[dist/] + $spec.files do |f|
  sh "git archive --format=tar HEAD | gzip > #{f.name}"
end

desc 'Upload gem and tar.gz distributables to rubyforge'
task 'release:rubyforge' => [package('.gem'), package('.tar.gz')] do |t|
  sh <<-SH
    rubyforge add_release wink rack-cache #{$spec.version} #{package('.gem')} &&
    rubyforge add_file    wink rack-cache #{$spec.version} #{package('.tar.gz')}
  SH
end

desc 'Upload gem to gemcutter.org'
task 'release:gemcutter' => [package('.gem')] do |t|
  sh "gem push #{package('.gem')}"
end

desc 'Upload gem to gemcutter and rubyforge'
task 'release' => ['release:gemcutter', 'release:rubyforge']

# GEMSPEC ===================================================================

file 'rack-cache.gemspec' => FileList['{lib,test}/**','Rakefile'] do |f|
  # read spec file and split out manifest section
  spec = File.read(f.name)
  parts = spec.split("  # = MANIFEST =\n")
  fail 'bad spec' if parts.length != 3
  # determine file list from git ls-files
  files = `git ls-files`.
    split("\n").sort.reject{ |file| file =~ /^\./ }.
    map{ |file| "    #{file}" }.join("\n")
  # piece file back together and write...
  parts[1] = "  s.files = %w[\n#{files}\n  ]\n"
  spec = parts.join("  # = MANIFEST =\n")
  spec.sub!(/s.date = '.*'/, "s.date = '#{Time.now.strftime("%Y-%m-%d")}'")
  File.open(f.name, 'w') { |io| io.write(spec) }
  puts "updated #{f.name}"
end
