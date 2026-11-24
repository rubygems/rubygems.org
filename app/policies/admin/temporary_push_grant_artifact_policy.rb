# frozen_string_literal: true

class Admin::TemporaryPushGrantArtifactPolicy < Admin::ApplicationPolicy
  class Scope < Admin::ApplicationPolicy::Scope
    def resolve
      rubygems_org_admin? ? scope.all : scope.none
    end
  end

  def avo_index? = rubygems_org_admin?
  def avo_show? = rubygems_org_admin?
  def avo_create? = rubygems_org_admin?
  def avo_destroy? = rubygems_org_admin? && record.temporary_push_grant.activated_at.nil?
end
