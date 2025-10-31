class Admin::SubscriptionPolicy < Admin::ApplicationPolicy
  class Scope < Admin::ApplicationPolicy::Scope
    def resolve
      if rubygems_org_admin?
        scope.all
      else
        scope.none
      end
    end
  end

  def avo_index?
    rubygems_org_admin?
  end

  def avo_show?
    rubygems_org_admin?
  end
end
