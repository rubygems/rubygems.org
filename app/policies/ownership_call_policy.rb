class OwnershipCallPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.none
    end
  end

  def create?
    record.rubygem.owned_by?(user) && record.user == user
  end

  def close?
    record.rubygem.owned_by?(user)
  end
end
