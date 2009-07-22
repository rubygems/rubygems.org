require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/packagetask'
require 'rake/gempackagetask'

require File.dirname(__FILE__) + '/lib/aws/s3'

def library_root
  File.dirname(__FILE__)
end

task :default => :test

Rake::TestTask.new do |test|
  test.pattern = 'test/*_test.rb'
  test.verbose = true
end

namespace :doc do
  Rake::RDocTask.new do |rdoc|  
    rdoc.rdoc_dir = 'doc'  
    rdoc.title    = "AWS::S3 -- Support for Amazon S3's REST api"  
    rdoc.options << '--line-numbers' << '--inline-source'
    rdoc.rdoc_files.include('README')
    rdoc.rdoc_files.include('COPYING')
    rdoc.rdoc_files.include('INSTALL')    
    rdoc.rdoc_files.include('lib/**/*.rb')
  end
  
  task :rdoc => 'doc:readme'
  
  task :refresh => :rerdoc do
    system 'open doc/index.html'
  end

  task :readme do
    require 'support/rdoc/code_info'
    RDoc::CodeInfo.parse('lib/**/*.rb')
    
    strip_comments = lambda {|comment| comment.gsub(/^# ?/, '')}
    docs_for       = lambda do |location| 
      info = RDoc::CodeInfo.for(location)
      raise RuntimeError, "Couldn't find documentation for `#{location}'" unless info
      strip_comments[info.comment]
    end
    
    open('README', 'w') do |file|
      file.write ERB.new(IO.read('README.erb')).result(binding)
    end
  end
  
  task :deploy => :rerdoc do
    sh %(scp -r doc marcel@rubyforge.org:/var/www/gforge-projects/amazon/)
  end
end

namespace :dist do  
  spec = Gem::Specification.new do |s|
    s.name              = 'aws-s3'
    s.version           = Gem::Version.new(AWS::S3::Version)
    s.summary           = "Client library for Amazon's Simple Storage Service's REST API"
    s.description       = s.summary
    s.email             = 'marcel@vernix.org'
    s.author            = 'Marcel Molina Jr.'
    s.has_rdoc          = true
    s.extra_rdoc_files  = %w(README COPYING INSTALL)
    s.homepage          = 'http://amazon.rubyforge.org'
    s.rubyforge_project = 'amazon'
    s.files             = FileList['Rakefile', 'lib/**/*.rb', 'bin/*', 'support/**/*.rb']
    s.executables       << 's3sh'
    s.test_files        = Dir['test/**/*']
    
    s.add_dependency 'xml-simple'
    s.add_dependency 'builder'
    s.add_dependency 'mime-types'
    s.rdoc_options  = ['--title', "AWS::S3 -- Support for Amazon S3's REST api",
                       '--main',  'README',
                       '--line-numbers', '--inline-source']
  end
    
  # Regenerate README before packaging
  task :package => 'doc:readme'
  Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_tar_gz = true
    pkg.package_files.include('{lib,script,test,support}/**/*')
    pkg.package_files.include('README')
    pkg.package_files.include('COPYING')
    pkg.package_files.include('INSTALL')
    pkg.package_files.include('Rakefile')
  end
  
  desc 'Install with gems'
  task :install => :repackage do
    sh "sudo gem i pkg/#{spec.name}-#{spec.version}.gem"
  end
  
  desc 'Uninstall gem'
  task :uninstall do
    sh "sudo gem uninstall #{spec.name} -x"
  end
  
  desc 'Reinstall gem'
  task :reinstall => [:uninstall, :install]
  
  task :confirm_release do
    print "Releasing version #{spec.version}. Are you sure you want to proceed? [Yn] "
    abort if STDIN.getc == ?n
  end
  
  desc 'Tag release'
  task :tag do
    sh %(git tag -a '#{spec.version}-release' -m 'Tagging #{spec.version} release')
    sh 'git push --tags'
  end
  
  desc 'Update changelog to include a release marker'
  task :add_release_marker_to_changelog do
    changelog = IO.read('CHANGELOG')
    changelog.sub!(/^head:/, "#{spec.version}:")
    
    open('CHANGELOG', 'w') do |file|
      file.write "head:\n\n#{changelog}"
    end
  end
  
  task :commit_changelog do
    sh %(git commit CHANGELOG -m "Bump changelog version marker for release")
    sh 'git push'
  end
  
  package_name = lambda {|specification| File.join('pkg', "#{specification.name}-#{specification.version}")}
  
  desc 'Push a release to rubyforge'
  task :release => [:confirm_release, :clean, :add_release_marker_to_changelog, :package, :commit_changelog, :tag] do 
    require 'rubyforge'
    package = package_name[spec]

    rubyforge = RubyForge.new.configure
    rubyforge.login
    
    user_config = rubyforge.userconfig
    user_config['release_changes'] = YAML.load_file('CHANGELOG')[spec.version.to_s].join("\n")
  
    version_already_released = lambda do
      releases = rubyforge.autoconfig['release_ids']
      releases.has_key?(spec.name) && releases[spec.name][spec.version.to_s]
    end
    
    abort("Release #{spec.version} already exists!") if version_already_released.call
    
    begin
      rubyforge.add_release(spec.rubyforge_project, spec.name, spec.version.to_s, "#{package}.tar.gz", "#{package}.gem")
      puts "Version #{spec.version} released!"
    rescue Exception => exception
      puts 'Release failed!'
      raise
    end
  end
  
  desc 'Upload a beta gem'
  task :push_beta_gem => [:clobber_package, :package] do
    beta_gem = package_name[spec]
    sh %(scp #{beta_gem}.gem  marcel@rubyforge.org:/var/www/gforge-projects/amazon/beta)
  end
  
  task :spec do
    puts spec.to_ruby
  end
end

desc 'Check code to test ratio'
task :stats do 
  library_files = FileList["#{library_root}/lib/**/*.rb"]
  test_files    = FileList["#{library_root}/test/**/*_test.rb"]
  count_code_lines = Proc.new do |lines| 
    lines.inject(0) do |code_lines, line|
      next code_lines if [/^\s*$/, /^\s*#/].any? {|non_code_line| non_code_line === line}
      code_lines + 1
    end
  end
  
  count_code_lines_for_files = Proc.new do |files|
    files.inject(0) {|code_lines, file| code_lines + count_code_lines[IO.read(file)]}
  end
  
  library_code_lines = count_code_lines_for_files[library_files]
  test_code_lines    = count_code_lines_for_files[test_files]
  ratio = Proc.new { sprintf('%.2f', test_code_lines.to_f / library_code_lines)}
  
  puts "Code LOC: #{library_code_lines}    Test LOC: #{test_code_lines}    Code to Test Ratio: 1:#{ratio.call}"
end

namespace :test do
  find_file = lambda do |name|
    file_name = lambda {|path| File.join(path, "#{name}.rb")}
    root = $:.detect do |path|
      File.exist?(file_name[path])
    end
    file_name[root] if root
  end
  
  TEST_LOADER = find_file['rake/rake_test_loader']
  multiruby   = lambda do |glob|
    system 'multiruby', TEST_LOADER, *Dir.glob(glob)
  end
    
  desc 'Check test coverage'
  task :coverage do
    system("rcov -x Library -x support --sort coverage #{File.join(library_root, 'test/*_test.rb')}")
    show_test_coverage_results
  end
  
  Rake::TestTask.new(:remote) do |test|
    test.pattern = 'test/remote/*_test.rb'
    test.verbose = true
  end
  
  Rake::TestTask.new(:all) do |test|
    test.pattern = 'test/**/*_test.rb'
    test.verbose = true
  end

  desc 'Check test coverage of full stack remote tests'
  task :full_coverage do
    system("rcov -x Library -x support --sort coverage #{File.join(library_root, 'test/remote/*_test.rb')} #{File.join(library_root, 'test/*_test.rb')}")
    show_test_coverage_results
  end
  
  desc 'Run local tests against multiple versions of Ruby'
  task :version_audit do
    multiruby['test/*_test.rb']
  end
  
  namespace :version_audit do
    desc 'Run remote tests against multiple versions of Ruby'
    task :remote do
      multiruby['test/remote/*_test.rb']
    end
    
    desc 'Run all tests against multiple versions of Ruby'
    task :all do
      multiruby['test/**/*_test.rb']
    end
  end
  
  def show_test_coverage_results
    system("open #{File.join(library_root, 'coverage/index.html')}") if PLATFORM['darwin']
  end
  
  desc 'Remove coverage products'
  task :clobber_coverage do
    rm_r 'coverage' rescue nil
  end
end

namespace :todo do
  class << TODOS = IO.read(File.join(library_root, 'TODO'))
    def items
      split("\n").grep(/^\[\s|X\]/)
    end
    
    def completed
      find_items_matching(/^\[X\]/)
    end
    
    def uncompleted
      find_items_matching(/^\[\s\]/)
    end
        
    def find_items_matching(regexp)
      items.grep(regexp).instance_eval do
        def display
          puts map {|item| "* #{item.sub(/^\[[^\]]\]\s/, '')}"}
        end
        self
      end
    end
  end
  
  desc 'Completed todo items'
  task :completed do
    TODOS.completed.display
  end
  
  desc 'Incomplete todo items'
  task :uncompleted do
    TODOS.uncompleted.display
  end
end if File.exists?(File.join(library_root, 'TODO'))

namespace :site do
  require 'erb'
  require 'rdoc/markup/simple_markup'
  require 'rdoc/markup/simple_markup/to_html'
  
  readme    = lambda { IO.read('README')[/^== Getting started\n(.*)/m, 1] }

  readme_to_html = lambda do
    handler = SM::ToHtml.new
    handler.instance_eval do
      require 'syntax'
      require 'syntax/convertors/html'
      def accept_verbatim(am, fragment) 
        syntax = Syntax::Convertors::HTML.for_syntax('ruby')
        @res << %(<div class="ruby">#{syntax.convert(fragment.txt, true)}</div>)
      end
    end
    SM::SimpleMarkup.new.convert(readme.call, handler)
  end
  
  desc 'Regenerate the public website page'
  task :build => 'doc:readme' do
    open('site/public/index.html', 'w') do |file|
      erb_data = {}
      erb_data[:readme] = readme_to_html.call
      file.write ERB.new(IO.read('site/index.erb')).result(binding)
    end
  end
  
  task :refresh => :build do
    system 'open site/public/index.html'
  end
  
  desc 'Update the live website'
  task :deploy => :build do
    site_files = FileList['site/public/*']
    site_files.delete_if {|file| File.directory?(file)}
    sh %(scp #{site_files.join ' '} marcel@rubyforge.org:/var/www/gforge-projects/amazon/)
  end
end 

task :clean => ['dist:clobber_package', 'doc:clobber_rdoc', 'test:clobber_coverage']
