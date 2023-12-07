class WebauthnCredentialPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def avo_show?
    Pundit.policy!(user, record.user).avo_show?
  end

  has_association :user
end
