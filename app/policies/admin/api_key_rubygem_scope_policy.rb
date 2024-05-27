class Admin::ApiKeyRubygemScopePolicy < Admin::ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def avo_show?
    policy!(user, record.ownership).avo_show?
  end
end
