class OrganizationPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
  end

  alias organization record

  def show?
    true
  end

  def update?
    organization_member_with_role?(user, :owner) || deny(t(:forbidden))
  end

  alias edit? update?

  def create?
    true
  end

  def add_gem?
    organization_member_with_role?(user, :admin) || deny(t(:forbidden))
  end

  def remove_gem?
    organization_member_with_role?(user, :owner) || deny(t(:forbidden))
  end

  def manage_memberships?
    organization_member_with_role?(user, :admin) || deny(t(:forbidden))
  end

  def list_memberships?
    organization_member_with_role?(user, :maintainer) || deny(t(:forbidden))
  end

  def invite_member?
    organization_member_with_role?(user, :admin) || deny(t(:forbidden))
  end

  def destroy?
    false # For now organizations cannot be deleted
  end
end
