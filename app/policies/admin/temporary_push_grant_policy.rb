# frozen_string_literal: true

class Admin::TemporaryPushGrantPolicy < Admin::ApplicationPolicy
  class Scope < Admin::ApplicationPolicy::Scope
    def resolve
      rubygems_org_admin? ? scope.all : scope.none
    end
  end

  has_association :artifacts
  has_association :approvals
  has_association :audits

  def avo_index? = rubygems_org_admin?
  def avo_show? = rubygems_org_admin?
  def avo_create? = rubygems_org_admin?
  # The scope is what operators approve; once activated or revoked it is fixed.
  def avo_update? = rubygems_org_admin? && record.activated_at.nil? && record.revoked_at.nil?
  def act_on? = rubygems_org_admin?
end
