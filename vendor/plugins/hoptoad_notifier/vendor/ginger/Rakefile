require 'rubygems'
require 'spec'
require 'rake/rdoctask'
require 'spec/rake/spectask'
require 'rake/gempackagetask'

$LOAD_PATH.unshift File.dirname(__FILE__) + '/lib'

require 'ginger'

spec = Gem::Specification.new do |s|
  s.name              = "ginger"
  s.version           = Ginger::Version::String
  s.summary           = "Run specs/tests multiple times through different gem versions."
  s.description       = "Run specs/tests multiple times through different gem versions."
  s.author            = "Pat Allan"
  s.email             = "pat@freelancing-gods.com"
  s.homepage          = "http://github.com/freelancing_god/ginger/tree"
  s.has_rdoc          = true
  s.rdoc_options     << "--title" << "Ginger" <<
                        "--line-numbers"
  s.rubyforge_project = "ginger"
  s.test_files        = FileList["spec/**/*_spec.rb"]
  s.files             = FileList[
    "lib/**/*.rb",
    "LICENCE",
    "README.textile"
  ]
  s.executables       = ["ginger"]
end

Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = true
  p.need_zip = true
end

desc "Generate ginger.gemspec file"
task :gemspec do
  File.open('ginger.gemspec', 'w') { |f|
    f.write spec.to_ruby
  }
end

desc "Run the specs under spec"
Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.spec_opts << "-c"
end

desc "Generate RCov reports"
Spec::Rake::SpecTask.new(:rcov) do |t|
  t.libs << 'lib'
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec', '--exclude', 'gems']
end