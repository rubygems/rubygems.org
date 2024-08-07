class Admin::IpAddressPolicy < Admin::ApplicationPolicy
  class Scope < Admin::ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end

  has_association :user_events
  has_association :rubygem_events
  has_association :organization_events

  def avo_index? = rubygems_org_admin?
  def avo_show? = rubygems_org_admin?
end
