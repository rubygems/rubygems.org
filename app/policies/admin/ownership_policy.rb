class Admin::OwnershipPolicy < Admin::ApplicationPolicy
  class Scope < Admin::ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end

  has_association :api_key_rubygem_scopes

  def avo_show?
    rubygems_org_admin?
  end
end
