class LinksetPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def avo_index?
    Pundit.policy!(user, Rubygem).avo_index?
  end

  def avo_show?
    Pundit.policy!(user, record.rubygem).avo_show?
  end
end
