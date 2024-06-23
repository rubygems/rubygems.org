class OIDC::PendingTrustedPublisherPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(user: user)
    end
  end

  def show?
    current_user?(record.user)
  end

  def create?
    current_user?(record.user)
  end

  def destroy?
    current_user?(record.user)
  end
end
