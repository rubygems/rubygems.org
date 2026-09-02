# frozen_string_literal: true

class Admin::PrefixReservationPolicy < Admin::ApplicationPolicy
  class Scope < Admin::ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end

  def avo_index? = rubygems_org_admin?
  def avo_show? = rubygems_org_admin?
  def avo_create? = rubygems_org_admin?
  # A prefix reservation is identified by its prefix and owner; correcting
  # either one is a destroy plus a create so both sides show up in the audit log.
  def avo_update? = false
  def avo_destroy? = rubygems_org_admin?
  def avo_search? = rubygems_org_admin?
end
