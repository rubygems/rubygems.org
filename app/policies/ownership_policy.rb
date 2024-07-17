class OwnershipPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
  end

  delegate :rubygem, to: :record

  def create?
    policy!(user, rubygem).add_owner?
  end

  def update?
    policy!(user, rubygem).update_owner?
  end

  def destroy?
    policy!(user, rubygem).remove_owner?
  end
end
