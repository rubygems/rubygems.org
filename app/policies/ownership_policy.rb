class OwnershipPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def avo_show?
    rubygems_org_admin?
  end

  has_association :api_key_rubygem_scopes
end
