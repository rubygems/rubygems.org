class OwnershipCallPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
  end

  delegate :rubygem, to: :record

  def create?
    rubygem_owned_by?(user) && current_user?(record.user)
  end

  def close?
    rubygem_owned_by?(user)
  end
end
