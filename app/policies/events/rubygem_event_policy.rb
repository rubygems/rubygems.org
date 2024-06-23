class Events::RubygemEventPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
  end

  delegate :rubygem, to: :record

  def show?
    rubygem.owned_by?(user)
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
