class GemTypo
  attr_reader :protected_gem

  def initialize(rubygem_name)
    @rubygem_name = rubygem_name
  end

  def protected_typo?
    return false if GemTypoException.where("upper(name) = upper(?)", @rubygem_name).any?

    return false if published_exact_name_matches.any?

    match = matched_protected_gem_names.pick(:name)
    return false unless match

    @protected_gem = match
    true
  end

  private

  def published_exact_name_matches
    Rubygem.with_versions.where("upper(name) = upper(?)", @rubygem_name)
  end

  def matched_protected_gem_names
    Rubygem.with_versions.where(
      "regexp_replace(upper(name), '[_-]', '', 'g') = regexp_replace(upper(?), '[_-]', '', 'g')",
      @rubygem_name
    )
  end
end
