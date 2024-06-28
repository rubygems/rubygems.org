class OwnershipCallPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
  end

  delegate :rubygem, to: :record

  def create?
    rubygem.owned_by?(user) && current_user?(record.user)
  end

  def close?
    rubygem.owned_by?(user)
  end
end
