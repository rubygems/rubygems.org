class IpAddressPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def avo_index? = rubygems_org_admin?
  def avo_show? = rubygems_org_admin?

  has_association :user_events
  has_association :rubygem_events
end
