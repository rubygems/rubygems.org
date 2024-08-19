class MembershipPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
  end

  def show?
    is_organization_member_with_role?(user)
  end

  def create?
    is_organization_member_with_role?(user, minimum_required_role: Access::ADMIN)
  end

  def update?
    is_organization_member_with_role?(user, minimum_required_role: Access::ADMIN)
  end

  def destroy?
    is_organization_member_with_role?(user, minimum_required_role: Access::ADMIN)
  end
end
