class RubygemPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
  end

  ABANDONED_RELEASE_AGE = 1.year
  ABANDONED_DOWNLOADS_MAX = 10_000

  alias rubygem record

  def show?
    true
  end

  def create?
    user.present?
  end

  def update?
    false
  end

  def destroy?
    false
  end

  def show_adoption?
    rubygem_owned_by?(user) || request_ownership?
  end

  def show_events?
    rubygem_owned_by?(user)
  end

  def request_ownership?
    return false if rubygem_owned_by?(user)
    return true if rubygem.ownership_calls.any?
    return deny("above maximum downloads to be considered abandoned") if rubygem.downloads >= ABANDONED_DOWNLOADS_MAX
    return false unless rubygem.latest_version&.created_at&.before?(ABANDONED_RELEASE_AGE.ago)
    true
  end

  def close_ownership_requests?
    rubygem_owned_by?(user)
  end

  def configure_trusted_publishers?
    rubygem_owned_by?(user)
  end

  def show_unconfirmed_ownerships?
    rubygem_owned_by?(user)
  end
end
