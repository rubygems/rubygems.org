class OrganizationPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
  end

  def show?
    true
  end

  def update?
    organization_member_with_role?(user, minimum_required_role: Access::OWNER)
  end

  def create?
    true
  end

  def add_gem?
    organization_member_with_role?(user, minimum_required_role: Access::OWNER)
  end

  def remove_gem?
    organization_member_with_role?(user, minimum_required_role: Access::OWNER)
  end

  def add_membership?
    organization_member_with_role?(user, minimum_required_role: Access::OWNER)
  end

  def update_membership?
    organization_member_with_role?(user, minimum_required_role: Access::OWNER)
  end

  def remove_membership?
    organization_member_with_role?(user, minimum_required_role: Access::OWNER)
  end

  def show_membership?
    organization_member_with_role?(user, minimum_required_role: Access::MAINTAINER)
  end

  def list_memberships?
    organization_member_with_role?(user, minimum_required_role: Access::MAINTAINER)
  end

  def destroy?
    false # For now organizations cannot be deleted
  end

  private

  def organization_member_with_role?(user, minimum_required_role:)
    record.memberships.exists?(["user_id = ? AND role >= ?", user.id, minimum_required_role])
  end
end
