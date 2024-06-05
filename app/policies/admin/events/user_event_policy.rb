class Admin::Events::UserEventPolicy < Admin::ApplicationPolicy
  class Scope < Admin::ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end

  has_association :user
  has_association :ip_address

  def avo_index? = rubygems_org_admin?
  def avo_show? = rubygems_org_admin?
end
