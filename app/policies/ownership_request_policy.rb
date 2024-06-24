class OwnershipRequestPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.none
    end
  end

  def create?
    return false unless record.user == user
    Pundit.policy!(user, record.rubygem).request_ownership?
  end

  def approve?
    record.rubygem.owned_by?(user)
  end

  def close?
    (user.present? && record.user == user) || record.rubygem.owned_by?(user)
  end
end
