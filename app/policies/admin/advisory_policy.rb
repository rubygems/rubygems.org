# frozen_string_literal: true

class Admin::AdvisoryPolicy < Admin::ApplicationPolicy
  class Scope < Admin::ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end

  has_association :rubygem

  def avo_index? = rubygems_org_admin?
  def avo_show? = rubygems_org_admin?
end
