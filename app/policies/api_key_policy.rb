class ApiKeyPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def avo_show?
    Pundit.policy!(user, record.user).avo_show?
  end

  has_association :api_key_rubygem_scope
  has_association :ownership
end
