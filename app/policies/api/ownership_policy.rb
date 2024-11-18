class Api::OwnershipPolicy < Api::ApplicationPolicy
  class Scope < Api::ApplicationPolicy::Scope
  end

  delegate :rubygem, to: :record

  def update?
    api_authorized?(rubygem, :update_owner?) &&
      user_authorized?(record, :update?)
  end
end
