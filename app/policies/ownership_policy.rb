class OwnershipPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
  end

  delegate :rubygem, to: :record

  def create?
    rubygem.owned_by?(user) && current_user?(record.authorizer)
  end

  def destroy?
    rubygem.owned_by?(user)
  end
end
