class OIDC::RubygemTrustedPublisherPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
  end

  delegate :rubygem, to: :record

  def show?
    rubygem_owned_by?(user, minimum_required_role: Access::OWNER)
  end

  def create?
    rubygem_owned_by?(user, minimum_required_role: Access::OWNER)
  end

  def destroy?
    rubygem_owned_by?(user, minimum_required_role: Access::OWNER)
  end
end
