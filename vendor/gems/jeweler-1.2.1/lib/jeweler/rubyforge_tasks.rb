require 'rake'
require 'rake/tasklib'
require 'rake/contrib/sshpublisher'


class Jeweler
  # Rake tasks for putting a Jeweler gem on Rubyforge.
  #
  # Jeweler::Tasks.new needs to be used before this.
  #
  # Basic usage:
  #
  #     Jeweler::RubyforgeTasks.new
  #
  # Easy enough, right?
  # 
  # There are a few options you can tweak:
  #
  #  * project: the rubyforge project to operate on. This defaults to whatever you specified in your gemspec. Defaults to your gem name.
  #  * remote_doc_path: the place to upload docs to on Rubyforge under /var/www/gforge-projects/#{project}/
  #
  class RubyforgeTasks < ::Rake::TaskLib
    # The RubyForge project to interact with. Defaults to whatever is in your jeweler gemspec.
    attr_accessor :project
    # The path to upload docs to. It is relative to /var/www/gforge-projects/#{project}/, and defaults to your gemspec's name
    attr_accessor :remote_doc_path
    # Task to be used for generating documentation, before they are uploaded. Defaults to rdoc.
    attr_accessor :doc_task

    attr_accessor :jeweler

    def initialize
      yield self if block_given?

      self.jeweler = Rake.application.jeweler

      self.remote_doc_path ||= jeweler.gemspec.name
      self.project ||= jeweler.gemspec.rubyforge_project
      self.doc_task ||= :rdoc

      define
    end

    def define
      namespace :rubyforge do

        desc "Release gem and RDoc documentation to RubyForge"
        task :release => ["rubyforge:release:gem", "rubyforge:release:docs"]

        namespace :release do
          desc "Release the current gem version to RubyForge."
          task :gem => [:gemspec, :build] do
            begin
              jeweler.release_gem_to_rubyforge
            rescue NoRubyForgeProjectInGemspecError => e
              abort "Setting up RubyForge requires that you specify a 'rubyforge_project' in your Jeweler::Tasks declaration"
            rescue MissingRubyForgePackageError => e
              abort "Rubyforge reported that the #{e.message} package isn't setup. Run rake rubyforge:setup to do so."
            rescue RubyForgeProjectNotConfiguredError => e
              abort "RubyForge reported that #{e.message} wasn't configured. This means you need to run 'rubyforge setup', 'rubyforge login', and 'rubyforge configure', or maybe the project doesn't exist on RubyForge"
            end
          end

          desc "Publish docs to RubyForge."
          task :docs => doc_task do
            config = YAML.load(
              File.read(File.expand_path('~/.rubyforge/user-config.yml'))
            )

            host = "#{config['username']}@rubyforge.org"
            remote_dir = "/var/www/gforge-projects/#{project}/#{remote_doc_path}"

            local_dir = case self.doc_task.to_sym
                        when :rdoc then 'rdoc'
                        when :yardoc then 'doc'
                        else
                          raise "Unsure what to run to generate documentation. Please set doc_task and re-run."
                        end

            sh %{rsync -av --delete #{local_dir}/ #{host}:#{remote_dir}}
          end
        end

        desc "Setup a rubyforge project for this gem"
        task :setup do
          begin 
            jeweler.setup_rubyforge
          rescue NoRubyForgeProjectInGemspecError => e
            abort "Setting up RubyForge requires that you specify a 'rubyforge_project' in your Jeweler::Tasks declaration"
          rescue RubyForgeProjectNotConfiguredError => e
            abort "The RubyForge reported that #{e.message} wasn't configured. This means you need to run 'rubyforge setup', 'rubyforge login', and 'rubyforge configure', or maybe the project doesn't exist on RubyForge"
          end
        end

      end
    end
  end
end
