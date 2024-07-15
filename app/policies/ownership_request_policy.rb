class OwnershipRequestPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
  end

  delegate :rubygem, to: :record

  def create?
    current_user?(record.user) && user_authorized?(rubygem, :request_ownership?)
  end

  def approve?
    rubygem_owned_by?(user)
  end

  def close?
    current_user?(record.user) || rubygem_owned_by?(user)
  end
end
