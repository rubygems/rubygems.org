class OwnershipCallPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.none
    end
  end

  def create?
    gem_owner? && same_user?(record.user)
  end

  def close?
    gem_owner?
  end
end
