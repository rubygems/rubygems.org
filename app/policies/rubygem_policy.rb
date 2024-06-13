class RubygemPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
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

  def show_events?
    record.owned_by?(user)
  end
end
