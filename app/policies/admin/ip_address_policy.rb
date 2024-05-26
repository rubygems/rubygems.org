class IpAddressPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  has_association :user_events
  has_association :rubygem_events

  def avo_index? = rubygems_org_admin?
  def avo_show? = rubygems_org_admin?
end
