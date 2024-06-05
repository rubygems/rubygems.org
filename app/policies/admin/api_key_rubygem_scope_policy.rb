class Admin::ApiKeyRubygemScopePolicy < Admin::ApplicationPolicy
  class Scope < Admin::ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end

  def avo_show?
    policy!(user, record.ownership).avo_show?
  end
end
