class VersionPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if rubygems_org_admin?
        scope.all
      else
        scope.indexed
      end
    end
  end

  def avo_index?
    rubygems_org_admin?
  end

  def avo_show?
    rubygems_org_admin?
  end

  def act_on?
    rubygems_org_admin?
  end

  has_association :dependencies
  has_association :gem_download
  has_association :deletion
end
