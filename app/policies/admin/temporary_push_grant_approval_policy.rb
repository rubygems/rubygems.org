# frozen_string_literal: true

# Approvals are recorded only through the Approve action, by the approving operator.
class Admin::TemporaryPushGrantApprovalPolicy < Admin::ApplicationPolicy
  class Scope < Admin::ApplicationPolicy::Scope
    def resolve
      rubygems_org_admin? ? scope.all : scope.none
    end
  end

  def avo_index? = rubygems_org_admin?
  def avo_show? = rubygems_org_admin?
end
