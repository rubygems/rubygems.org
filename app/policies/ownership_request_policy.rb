class OwnershipRequestPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
  end

  delegate :rubygem, to: :record

  def create?
    current_user?(record.user) && Pundit.policy!(user, rubygem).request_ownership?
  end

  def approve?
    rubygem.owned_by?(user)
  end

  def close?
    current_user?(record.user) || rubygem.owned_by?(user)
  end
end
