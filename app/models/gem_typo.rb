require "rubygems/text"

class GemTypo
  attr_reader :protected_gem

  include Gem::Text

  DOWNLOADS_THRESHOLD = 10_000_000
  SIZE_THRESHOLD = 4

  def initialize(rubygem_name)
    @rubygem_name       = rubygem_name.downcase
    @distance_threshold = distance_threshold
  end

  def protected_typo?
    return false if @rubygem_name.size < GemTypo::SIZE_THRESHOLD

    gem_typo_exceptions = GemTypoException.all.pluck(:name)
    return false if gem_typo_exceptions.include?(@rubygem_name)

    protected_gems.each do |protected_gem|
      distance = levenshtein_distance(@rubygem_name, protected_gem)
      if distance <= @distance_threshold
        @protected_gem = protected_gem
        return true
      end
    end

    false
  end

  private

  def distance_threshold
    @rubygem_name.size == GemTypo::SIZE_THRESHOLD ? 1 : 2
  end

  def protected_gems
    Rubygem.joins(:gem_download)
      .where("gem_downloads.count > ?", GemTypo::DOWNLOADS_THRESHOLD)
      .where.not(name: @rubygem_name)
      .pluck(:name)
  end
end
