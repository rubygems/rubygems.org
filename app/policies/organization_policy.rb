class OrganizationPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
  end

  def show?
    true
  end

  def update?
    is_member_with_role?(user, minimum_required_role: Access::OWNER)
  end

  def create?
    false # TODO
  end

  def destroy?
    false # For now organizations cannot be deleted
  end

  private

  def is_member_with_role?(user, minimum_required_role:)
    record.memberships.exists?(['user_id = ? AND role >= ?', user.id, minimum_required_role])
  end
end
