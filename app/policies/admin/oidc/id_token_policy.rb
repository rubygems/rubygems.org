class Admin::OIDC::IdTokenPolicy < Admin::ApplicationPolicy
  class Scope < Admin::ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end

  has_association :provider
  has_association :api_key_role
  has_association :api_key

  def avo_index? = rubygems_org_admin?
  def avo_show? = rubygems_org_admin?
end
