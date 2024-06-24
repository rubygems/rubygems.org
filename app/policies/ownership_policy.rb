class OwnershipPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.none # unused
    end
  end

  def create?
    gem_owner? && same_user?(record.authorizer)
  end

  def destroy?
    gem_owner?
  end
end
