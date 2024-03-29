class OIDC::ProviderPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def avo_index? = rubygems_org_admin?
  def avo_show? = rubygems_org_admin?
  def avo_create? = rubygems_org_admin?
  def avo_update? = rubygems_org_admin?
  def act_on? = rubygems_org_admin?

  has_association :api_key_roles
end
