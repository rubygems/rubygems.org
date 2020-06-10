require "rubygems/text"

class GemTypo
  attr_reader :protected_gem

  def initialize(rubygem_name)
    @rubygem_name = rubygem_name
  end

  def protected_typo?
    gem_typo_exceptions = GemTypoException.all.pluck(:name)
    return false if gem_typo_exceptions.include?(@rubygem_name)
    
    return false if published_exact_name_matches.any?

    match = matched_protected_gem_names.select(:id, :name).first
    return false unless match

    @protected_gem = match.name
    true
  end

  private

  def published_exact_name_matches
    Rubygem.joins(:versions).where(
      "versions.yanked_at IS NULL AND upper(rubygems.name) = upper(?)",
      @rubygem_name
    )
  end

  def matched_protected_gem_names
    Rubygem.where(
      "upper(name) != upper(?) AND regexp_replace(upper(name), '[_-]', '', 'g') = regexp_replace(upper(?), '[_-]', '', 'g')",
      @rubygem_name,
      @rubygem_name
    )
  end
end
