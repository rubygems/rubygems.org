class Admin::MembershipPolicy < Admin::ApplicationPolicy
  class Scope < Admin::ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end

  def avo_show?
    rubygems_org_admin?
  end
end
