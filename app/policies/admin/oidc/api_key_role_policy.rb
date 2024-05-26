class OIDC::ApiKeyRolePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  has_association :provider
  has_association :id_tokens

  def avo_index? = rubygems_org_admin?
  def avo_show? = rubygems_org_admin?
  def avo_create? = rubygems_org_admin?
  def avo_update? = rubygems_org_admin?
  def act_on? = rubygems_org_admin?
end
