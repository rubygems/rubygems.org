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

  def configure_oidc?
    rubygem_owned_by_with_role?(user, minimum_required_role: :owner)
  end

  def configure_trusted_publishers?
    rubygem_owned_by_with_role?(user, minimum_required_role: :owner)
  end

  def manage_adoption?
    rubygem_owned_by_with_role?(user, minimum_required_role: :owner)
  end

  def request_ownership?
    return allow if rubygem.ownership_calls.any?
    return false if rubygem.downloads >= ABANDONED_DOWNLOADS_MAX
    return false if rubygem.latest_version.nil? || rubygem.latest_version.created_at.after?(ABANDONED_RELEASE_AGE.ago)
    allow
  end

  def show_adoption?
    manage_adoption? || request_ownership?
  end

  def show_events?
    rubygem_owned_by?(user)
  end

  def close_ownership_requests?
    rubygem_owned_by_with_role?(user, minimum_required_role: :owner)
  end

  def show_unconfirmed_ownerships?
    rubygem_owned_by_with_role?(user, minimum_required_role: :owner)
  end

  def add_owner?
    rubygem_owned_by_with_role?(user, minimum_required_role: :owner)
  end

  def update_owner?
    rubygem_owned_by_with_role?(user, minimum_required_role: :owner)
  end

  def remove_owner?
    rubygem_owned_by_with_role?(user, minimum_required_role: :owner)
  end
end
