class GemTypo
  DOWNLOADS_THRESHOLD = 10_000
  LAST_RELEASE_TIME   = 5.years.ago

  attr_reader :protected_gem

  def initialize(rubygem_name)
    @rubygem_name = rubygem_name
  end

  def protected_typo?
    return false if GemTypoException.where("upper(name) = upper(?)", @rubygem_name).any?

    return false if published_exact_name_matches.any?

    match = matched_protected_gem_name
    return false if not_protected?(match)

    @protected_gem = match.name
    true
  end

  private

  def published_exact_name_matches
    Rubygem.with_versions.where("upper(name) = upper(?)", @rubygem_name)
  end

  def matched_protected_gem_name
    Rubygem.with_versions.find_by(
      "regexp_replace(upper(name), '[_-]', '', 'g') = regexp_replace(upper(?), '[_-]', '', 'g')",
      @rubygem_name
    )
  end

  def not_protected?(rubygem)
    return true unless rubygem
    rubygem.downloads < DOWNLOADS_THRESHOLD && rubygem.versions.most_recent.created_at < LAST_RELEASE_TIME
  end
end
