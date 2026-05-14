# frozen_string_literal: true

class Admin::BlockedEmailDomainPolicy < Admin::ApplicationPolicy
  class Scope < Admin::ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end

  def avo_index? = rubygems_org_admin?
  def avo_show? = rubygems_org_admin?
  def avo_create? = rubygems_org_admin?
  def avo_update? = rubygems_org_admin? && !record&.upstream?
  def avo_destroy? = rubygems_org_admin? && !record&.upstream?

  # NOTE: `act_on?` is resource-level (Avo does not pass per-record context).
  # Per-row protection for upstream rows lives in avo_update?/avo_destroy?.
  # Any future Avo::Action targeting BlockedEmailDomain MUST guard against
  # upstream rows in its handle block, e.g.:
  #   records = records.reject(&:upstream?)
  # Bulk actions that bypass this guard will defeat the sync's source-of-truth.
  def act_on? = rubygems_org_admin?
end
