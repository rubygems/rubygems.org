class Admin::ApiKeyPolicy < Admin::ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  has_association :api_key_rubygem_scope
  has_association :ownership
  has_association :oidc_id_token

  def avo_show?
    policy!(user, record.owner).avo_show?
  end
end
