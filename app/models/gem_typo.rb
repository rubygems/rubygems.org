require 'rubygems/text'

class GemTypo
  PROTECTED_GEMS = [
    'rspec-core',
    'diff-lcs',
    'rspec-expectations',
    'rspec-mocks',
    'rspec',
    'bundler',
    'rspec-support',
    'multi_json',
    'rack',
    'rake'
  ].freeze

  DISTANCE_THRESHOLD = 1

  GEM_EXCEPTIONS = [
    'rspec-coreZ'
    # Add exceptions here to manage gems which share a close distance,
    # but are manually reviewed and accepted by rubygems team
  ].freeze

  include Gem::Text

  def initialize(rubygem_name, opts = {})
    @rubygem_name = rubygem_name
    @protected_gems = opts[:protected_gems] || GemTypo::PROTECTED_GEMS
    @distance_threshold = opts[:distance_threshold] || GemTypo::DISTANCE_THRESHOLD
    @gem_exceptions = opts[:gem_exceptions] || GemTypo::GEM_EXCEPTIONS
  end

  def protected_typo?
    @protected_gems.each do |protected_gem|
      return false if @rubygem_name == protected_gem
      distance = levenshtein_distance(@rubygem_name, protected_gem)
      if distance <= @distance_threshold &&
          !@gem_exceptions.include?(@rubygem_name)
        return true
      end
    end

    false
  end
end
