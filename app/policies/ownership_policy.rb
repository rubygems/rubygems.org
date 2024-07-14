class OwnershipPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
  end

  delegate :rubygem, to: :record

  def create?
    rubygem_owned_by?(user) && current_user?(record.authorizer)
  end

  def destroy?
    rubygem_owned_by?(user)
  end
end
