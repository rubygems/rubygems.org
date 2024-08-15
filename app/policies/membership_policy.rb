class MembershipPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
  end

  def show?
  end

  def create?
  end

  def update?
  end

  def destroy?
  end
end
