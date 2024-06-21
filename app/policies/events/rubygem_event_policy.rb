class Events::RubygemEventPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.none
    end
  end

  def show?
    record.rubygem.owned_by?(user)
  end

  def create?
    false
  end

  def update?
    false
  end

  def destroy?
    false
  end
end
