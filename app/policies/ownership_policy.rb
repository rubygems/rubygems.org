class OwnershipPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.none # unused
    end
  end

  def create?
    record.rubygem.owned_by?(user) && record.authorizer == user
  end

  def destroy?
    record.rubygem.owned_by?(user)
  end
end
