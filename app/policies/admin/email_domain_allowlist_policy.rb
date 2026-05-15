# frozen_string_literal: true

class Admin::EmailDomainAllowlistPolicy < Admin::ApplicationPolicy
  class Scope < Admin::ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end

  def avo_index? = rubygems_org_admin?
  def avo_show? = rubygems_org_admin?
  # Create/update/destroy are routed through audited Avo Actions
  # (AllowlistEmailDomain, UnallowlistEmailDomain) — vanilla CRUD is disabled
  # so every mutation is recorded against an Admin::GitHubUser with a
  # justification.
  def avo_create? = false
  def avo_update? = false
  def avo_destroy? = false
  def act_on? = rubygems_org_admin?
end
