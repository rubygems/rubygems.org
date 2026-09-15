# frozen_string_literal: true

class Admin::BlockedEmailDomainPolicy < Admin::ApplicationPolicy
  class Scope < Admin::ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end

  def avo_index? = rubygems_org_admin?
  def avo_show? = rubygems_org_admin?
  # Create/update/destroy are routed through audited Avo Actions
  # (BlockEmailDomain, UnblockEmailDomain) — vanilla CRUD is disabled so every
  # mutation is recorded against an Admin::GitHubUser with a justification.
  def avo_create? = false
  def avo_update? = false
  def avo_destroy? = false

  # NOTE: `act_on?` is resource-level (Avo does not pass per-record context).
  # The per-record visibility/upstream guard lives in the action itself
  # (UnblockEmailDomain checks record.manual? in its visibility lambda and
  # raises if asked to operate on an upstream row).
  def act_on? = rubygems_org_admin?
end
