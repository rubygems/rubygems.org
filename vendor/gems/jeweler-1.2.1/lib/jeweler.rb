require 'date'
require 'rubygems/user_interaction'
require 'rubygems/builder'
require 'rubyforge'

require 'jeweler/errors'
require 'jeweler/version_helper'
require 'jeweler/gemspec_helper'
require 'jeweler/generator'
require 'jeweler/generator/options'
require 'jeweler/generator/application'

require 'jeweler/commands'

require 'jeweler/tasks'
require 'jeweler/gemcutter_tasks'
require 'jeweler/rubyforge_tasks'

require 'jeweler/specification'

# A Jeweler helps you craft the perfect Rubygem. Give him a gemspec, and he takes care of the rest.
class Jeweler

  attr_reader :gemspec, :gemspec_helper, :version_helper
  attr_accessor :base_dir, :output, :repo, :commit, :rubyforge

  def initialize(gemspec, base_dir = '.')
    raise(GemspecError, "Can't create a Jeweler with a nil gemspec") if gemspec.nil?

    @gemspec = gemspec
    @gemspec.extend(Specification)
    @gemspec.set_jeweler_defaults(base_dir)

    @base_dir       = base_dir
    @repo           = Git.open(base_dir) if in_git_repo?
    @version_helper = Jeweler::VersionHelper.new(base_dir)
    @output         = $stdout
    @commit         = true
    @gemspec_helper = GemSpecHelper.new(gemspec, base_dir)
    @rubyforge      = RubyForge.new
  end

  # Major version, as defined by the gemspec's Version module.
  # For 1.5.3, this would return 1.
  def major_version
    @version_helper.major
  end

  # Minor version, as defined by the gemspec's Version module.
  # For 1.5.3, this would return 5.
  def minor_version
    @version_helper.minor
  end

  # Patch version, as defined by the gemspec's Version module.
  # For 1.5.3, this would return 5.
  def patch_version
    @version_helper.patch
  end

  # Human readable version, which is used in the gemspec.
  def version
    @version_helper.to_s
  end

  # Writes out the gemspec
  def write_gemspec
    Jeweler::Commands::WriteGemspec.build_for(self).run
  end

  # Validates the project's gemspec from disk in an environment similar to how 
  # GitHub would build from it. See http://gist.github.com/16215
  def validate_gemspec
    Jeweler::Commands::ValidateGemspec.build_for(self).run
  end

  # is the project's gemspec from disk valid?
  def valid_gemspec?
    gemspec_helper.valid?
  end

  def build_gem
    Jeweler::Commands::BuildGem.build_for(self).run
  end

  def install_gem
    Jeweler::Commands::InstallGem.build_for(self).run
  end

  # Bumps the patch version.
  #
  # 1.5.1 -> 1.5.2
  def bump_patch_version()
    Jeweler::Commands::Version::BumpPatch.build_for(self).run
  end

  # Bumps the minor version.
  #
  # 1.5.1 -> 1.6.0
  def bump_minor_version()
    Jeweler::Commands::Version::BumpMinor.build_for(self).run
  end

  # Bumps the major version.
  #
  # 1.5.1 -> 2.0.0
  def bump_major_version()
    Jeweler::Commands::Version::BumpMajor.build_for(self).run
  end

  # Bumps the version, to the specific major/minor/patch version, writing out the appropriate version.rb, and then reloads it.
  def write_version(major, minor, patch, options = {})
    command = Jeweler::Commands::Version::Write.build_for(self)
    command.major = major
    command.minor = minor
    command.patch = patch

    command.run
  end

  def release
    Jeweler::Commands::Release.build_for(self).run
  end

  def release_gem_to_gemcutter
    Jeweler::Commands::ReleaseToGemcutter.build_for(self).run
  end

  def release_gem_to_rubyforge
    Jeweler::Commands::ReleaseToRubyforge.build_for(self).run
  end

  def setup_rubyforge
    Jeweler::Commands::SetupRubyforge.build_for(self).run
  end

  def check_dependencies(type = nil)
    command = Jeweler::Commands::CheckDependencies.build_for(self)
    command.type = type

    command.run
  end

  def in_git_repo?
    File.exists?(File.join(self.base_dir, '.git'))
  end

  def version_exists?
    File.exists?(@version_helper.plaintext_path) || File.exists?(@version_helper.yaml_path)
  end

end

