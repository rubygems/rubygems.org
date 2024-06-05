class Admin::WebauthnVerificationPolicy < Admin::ApplicationPolicy
  class Scope < Admin::ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end

  has_association :user

  def avo_show?
    policy!(user, record.user).avo_show?
  end
end
