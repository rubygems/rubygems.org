class Admin::GitHubUserPolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      if rubygems_org_admin?
        scope.all
      else
        scope.where(id: user.id)
      end
    end
  end

  def avo_index?
    rubygems_org_admin?
  end

  def avo_show?
    rubygems_org_admin?
  end

  has_association :audits
end
