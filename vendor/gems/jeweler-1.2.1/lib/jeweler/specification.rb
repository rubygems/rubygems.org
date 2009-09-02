require 'rubygems/specification'

class Jeweler
  # Extend a Gem::Specification instance with this module to give it Jeweler
  # super-cow powers.
  module Specification

    def self.filelist_attribute(name)
      code = %{
        def #{name}
          @#{name} ||= FileList[]
        end
        def #{name}=(value)
          @#{name} = FileList[value]
        end
      }

      module_eval code, __FILE__, __LINE__ - 9
    end

    filelist_attribute :files
    filelist_attribute :test_files
    filelist_attribute :extra_rdoc_files


    # Assigns the Jeweler defaults to the Gem::Specification
    def set_jeweler_defaults(base_dir)
      Dir.chdir(base_dir) do
        if blank?(files) && File.directory?(File.join(base_dir, '.git'))
          repo = Git.open(base_dir)
          self.files = repo.ls_files.keys - repo.lib.ignored_files
        end

        if blank?(test_files) && File.directory?(File.join(base_dir, '.git'))
          repo = Git.open(base_dir)
          self.test_files = FileList['{spec,test,examples}/**/*.rb'] - repo.lib.ignored_files
        end

        if blank?(executables)
          self.executables = Dir["bin/*"].map { |f| File.basename(f) }
        end

        self.has_rdoc = true
        rdoc_options << '--charset=UTF-8'

        if blank?(extra_rdoc_files)
          self.extra_rdoc_files = FileList["README*", "ChangeLog*", "LICENSE*"]
        end
      end
    end

    # Used by Specification#to_ruby to generate a ruby-respresentation of a Gem::Specification
    def ruby_code(obj)
      case obj
      when Rake::FileList then obj.to_a.inspect
      else super
      end
    end

    private

    def blank?(value)
      value.nil? || value.empty?
    end
  end
end
