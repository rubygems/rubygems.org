# frozen_string_literal: true

class Admin::SponsorPolicy < Admin::ApplicationPolicy
  class Scope < Admin::ApplicationPolicy::Scope
    def resolve
      rubygems_org_admin? ? scope.all : scope.none
    end
  end

  def avo_index? = rubygems_org_admin?
  def avo_show? = rubygems_org_admin?
  def avo_create? = rubygems_org_admin?
  def avo_update? = rubygems_org_admin?
  def avo_destroy? = rubygems_org_admin?
  def act_on? = rubygems_org_admin?
  def upload_logo? = rubygems_org_admin?
  # Replace logos through the audited edit form instead of removing a required logo.
  def delete_logo? = false
  def download_logo? = rubygems_org_admin?
end
