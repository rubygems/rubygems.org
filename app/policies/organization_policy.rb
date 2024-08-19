class OrganizationPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
  end

  def show?
    true
  end

  def update?
    is_organization_member_with_role?(user, minimum_required_role: Access::OWNER)
  end

  def create?
    true
  end

  def add_gem?
    is_organization_member_with_role?(user, minimum_required_role: Access::OWNER)
  end

  def remove_gem?
    is_organization_member_with_role?(user, minimum_required_role: Access::OWNER)
  end

  def destroy?
    false # For now organizations cannot be deleted
  end
end
