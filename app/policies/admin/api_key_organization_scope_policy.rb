# frozen_string_literal: true

class Admin::ApiKeyOrganizationScopePolicy < Admin::ApplicationPolicy
  class Scope < Admin::ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end

  def avo_show?
    policy!(user, record.membership).avo_show?
  end
end
