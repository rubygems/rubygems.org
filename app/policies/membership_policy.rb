class MembershipPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
  end

  alias membership record
  delegate :organization, to: :membership

  def create?
    minimum_required_role = membership.owner? ? :owner : :admin
    organization_member_with_role?(user, minimum_required_role) || deny(t(:forbidden))
  end

  def update?
    minimum_required_role = :owner if membership.role_was.to_s == "owner" || membership.owner?
    minimum_required_role ||= :admin
    organization_member_with_role?(user, minimum_required_role) || deny(t(:forbidden))
  end

  alias edit? update?

  def destroy?
    minimum_required_role = membership.owner? ? :owner : :admin
    organization_member_with_role?(user, minimum_required_role) || deny(t(:forbidden))
  end
end
