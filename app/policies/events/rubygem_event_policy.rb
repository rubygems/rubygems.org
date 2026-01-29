class Events::RubygemEventPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
  end

  delegate :rubygem, to: :record

  def show?
    GemPermissions.new(rubygem, user).can_push?
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
