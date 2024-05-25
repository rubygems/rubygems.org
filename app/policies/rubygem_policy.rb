class RubygemPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.none # unused
    end
  end

  def show?
    true
  end

  def create?
    user.present?
  end

  def update?
    false
  end

  def destroy?
    false
  end

  def show_unconfirmed_ownerships?
    record.owned_by?(user)
  end
end
