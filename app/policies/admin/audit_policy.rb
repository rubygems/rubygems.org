class AuditPolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      if rubygems_org_admin?
        scope.all
      else
        scope.where(admin_github_user: current_user)
      end
    end
  end

  def avo_index?
    true
  end

  def avo_show?
    true
  end
end
