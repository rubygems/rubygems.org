class OIDC::RubygemTrustedPublisherPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
  end

  delegate :rubygem, to: :record

  def show?
    rubygem_owned_by_with_role?(user, minimum_required_role: :owner, minimum_required_org_role: :admin)
  end

  def create?
    rubygem_owned_by_with_role?(user, minimum_required_role: :owner, minimum_required_org_role: :admin)
  end

  def destroy?
    rubygem_owned_by_with_role?(user, minimum_required_role: :owner, minimum_required_org_role: :admin)
  end
end
