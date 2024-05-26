class WebauthnVerificationPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  has_association :user

  def avo_show?
    Pundit.policy!(user, record.user).avo_show?
  end
end
