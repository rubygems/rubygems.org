class GemNameReservationPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def avo_index?
    true
  end

  def avo_show?
    true
  end

  def avo_create?
    rubygems_org_admin?
  end

  def avo_destroy?
    rubygems_org_admin?
  end

  def avo_search?
    true
  end
end
