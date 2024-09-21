class OwnershipPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
  end

  delegate :rubygem, to: :record

  def create?
    policy!(user, rubygem).add_owner?
  end

  def update?
    return deny(t("owners.update.update_current_user_role")) if current_user?(record.user)
    policy!(user, rubygem).update_owner?
  end
  alias edit? update?

  def destroy?
    policy!(user, rubygem).remove_owner?
  end
end
