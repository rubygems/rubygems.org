# frozen_string_literal: true

class GemTypo
  DOWNLOADS_THRESHOLD = 10_000
  LAST_RELEASE_TIME   = 5.years.ago

  attr_reader :protected_gem

  def initialize(rubygem_name, pushed_by: nil)
    @rubygem_name = rubygem_name
    @pushed_by = pushed_by
  end

  # `pushed_by` is the gem's owner for this push (a User or a trusted publisher).
  # Both respond to `owns_gem?`, matching the ownership check in Pusher#authorize.
  def protected_typo?
    return false if GemTypoException.where("upper(name) = upper(?)", @rubygem_name).any?

    return false if published_exact_name_matches.any?

    # Only gems that are themselves protected (popular/recent enough) can block a
    # too-similar push. Allow an author to publish a too-similar name when every
    # colliding protected gem is one they already own (e.g. a renamed/consolidated
    # variant of their own gem) -- there is no impersonation risk in that case.
    protected_match = protected_matches.find { |gem| !owned_by_pusher?(gem) }
    return false unless protected_match

    @protected_gem = protected_match.name
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

  def protected_matches
    matched_protected_gem_names.reject { |gem| not_protected?(gem) }
  end

  def owned_by_pusher?(rubygem)
    @pushed_by.present? && @pushed_by.owns_gem?(rubygem)
  end

  def not_protected?(rubygem)
    return true unless rubygem
    rubygem.downloads < DOWNLOADS_THRESHOLD && rubygem.most_recent_version.created_at < LAST_RELEASE_TIME
  end
end
