class Events::RubygemEventPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.none
    end
  end

  def show?
    gem_owner?
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
