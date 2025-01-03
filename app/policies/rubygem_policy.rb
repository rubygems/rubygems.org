class RubygemPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
  end

  ABANDONED_RELEASE_AGE = 1.year
  ABANDONED_DOWNLOADS_MAX = 10_000

  alias rubygem record
  delegate :organization, to: :rubygem

  def create?
    user.present?
  end

  def configure_oidc?
    rubygem_owned_by_with_role?(user, minimum_required_role: :owner, minimum_required_org_role: :admin)
  end

  def configure_trusted_publishers?
    rubygem_owned_by_with_role?(user, minimum_required_role: :owner, minimum_required_org_role: :admin)
  end

  def show_events?
    rubygem_owned_by?(user)
  end

  def show_unconfirmed_ownerships?
    rubygem_owned_by_with_role?(user, minimum_required_role: :owner, minimum_required_org_role: :admin)
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
