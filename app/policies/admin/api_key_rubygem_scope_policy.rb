class ApiKeyRubygemScopePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def avo_show?
    Pundit.policy!(user, record.ownership).avo_show?
  end
end
