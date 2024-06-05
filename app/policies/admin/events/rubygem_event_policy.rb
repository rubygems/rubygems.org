class Events::RubygemEventPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  has_association :rubygem
  has_association :ip_address

  def avo_index? = rubygems_org_admin?
  def avo_show? = rubygems_org_admin?
end
