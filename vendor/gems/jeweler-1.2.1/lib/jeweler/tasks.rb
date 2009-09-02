require 'rake'
require 'rake/tasklib'

class Rake::Application
  attr_accessor :jeweler
end

class Jeweler
  # Rake tasks for managing your gem.
  #
  # Here's a basic example of using it:
  #
  #   Jeweler::Tasks.new do |gem|
  #     gem.name = "jeweler"
  #     gem.summary = "Simple and opinionated helper for creating Rubygem projects on GitHub"
  #     gem.email = "josh@technicalpickles.com"
  #     gem.homepage = "http://github.com/technicalpickles/jeweler"
  #     gem.description = "Simple and opinionated helper for creating Rubygem projects on GitHub"
  #     gem.authors = ["Josh Nichols"]
  #   end
  #
  # The block variable gem is actually a Gem::Specification, so you can do anything you would normally do with a Gem::Specification. For more details, see the official gemspec reference: http://docs.rubygems.org/read/chapter/20
  #
  # Jeweler fills in a few reasonable defaults for you:
  #
  # [gem.files] a Rake::FileList of anything that is in git and not gitignored. You can include/exclude this default set, or override it entirely
  # [gem.test_files] Similar to gem.files, except it's only things under the spec, test, or examples directory.
  # [gem.extra_rdoc_files] a Rake::FileList including files like README*, ChangeLog*, and LICENSE*
  # [gem.executables] uses anything found in the bin/ directory. You can override this.
  #
  class Tasks < ::Rake::TaskLib
    attr_accessor :gemspec, :jeweler

    def initialize(gemspec = nil, &block)
      @gemspec = gemspec || Gem::Specification.new
      @jeweler = Jeweler.new(@gemspec)
      yield @gemspec if block_given?

      Rake.application.jeweler = @jeweler
      define
    end

  private
    def define
      task :version_required do
        unless jeweler.version_exists?
          abort "Expected VERSION or VERSION.yml to exist. See version:write to create an initial one."
        end
      end

      desc "Build gem"
      task :build do
        jeweler.build_gem
      end

      desc "Install gem using sudo"
      task :install => :build do
        jeweler.install_gem
      end

      desc "Generate and validates gemspec"
      task :gemspec => ['gemspec:generate', 'gemspec:validate']

      namespace :gemspec do
        desc "Validates the gemspec"
        task :validate => :version_required do
          jeweler.validate_gemspec
        end

        desc "Generates the gemspec, using version from VERSION"
        task :generate => :version_required do
          jeweler.write_gemspec
        end
      end

      desc "Displays the current version"
      task :version => :version_required do
        $stdout.puts "Current version: #{jeweler.version}"
      end

      namespace :version do
        desc "Writes out an explicit version. Respects the following environment variables, or defaults to 0: MAJOR, MINOR, PATCH"
        task :write do
          major, minor, patch = ENV['MAJOR'].to_i, ENV['MINOR'].to_i, ENV['PATCH'].to_i
          jeweler.write_version(major, minor, patch, :announce => false, :commit => false)
          $stdout.puts "Updated version: #{jeweler.version}"
        end

        namespace :bump do
          desc "Bump the gemspec by a major version."
          task :major => [:version_required, :version] do
            jeweler.bump_major_version
            $stdout.puts "Updated version: #{jeweler.version}"
          end

          desc "Bump the gemspec by a minor version."
          task :minor => [:version_required, :version] do
            jeweler.bump_minor_version
            $stdout.puts "Updated version: #{jeweler.version}"
          end

          desc "Bump the gemspec by a patch version."
          task :patch => [:version_required, :version] do
            jeweler.bump_patch_version
            $stdout.puts "Updated version: #{jeweler.version}"
          end
        end
      end

      desc "Release the current version. Includes updating the gemspec, pushing, and tagging the release"
      task :release do
        jeweler.release
      end

      desc "Check that runtime and development dependencies are installed" 
      task :check_dependencies do
        jeweler.check_dependencies
      end

      namespace :check_dependencies do
        desc "Check that runtime dependencies are installed"
        task :runtime  do
          jeweler.check_dependencies(:runtime)
        end

        desc"Check that development dependencies are installed"
        task :development do
          jeweler.check_dependencies(:development)
        end

      end
      
    end
  end
end
