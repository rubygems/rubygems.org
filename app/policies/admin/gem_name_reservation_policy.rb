class Admin::GemNameReservationPolicy < Admin::ApplicationPolicy
  class Scope < Admin::ApplicationPolicy::Scope
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
