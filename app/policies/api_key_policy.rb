class ApiKeyPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def avo_show?
    Pundit.policy!(user, record.owner).avo_show?
  end

  has_association :api_key_rubygem_scope
  has_association :ownership
  has_association :oidc_id_token
end
