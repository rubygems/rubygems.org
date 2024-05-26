class SendgridEventPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def avo_index?
    rubygems_org_admin?
  end

  def avo_show?
    rubygems_org_admin?
  end
end
