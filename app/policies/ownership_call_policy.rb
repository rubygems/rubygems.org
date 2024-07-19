class OwnershipCallPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
  end

  delegate :rubygem, to: :record

  def create?
    user_authorized?(rubygem, :manage_adoption?)
  end

  def close?
    user_authorized?(rubygem, :manage_adoption?)
  end
end
