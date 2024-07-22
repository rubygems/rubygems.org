class OIDC::RubygemTrustedPublisherPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
  end

  delegate :rubygem, to: :record

  def show?
    rubygem_owned_by?(user)
  end

  def create?
    rubygem_owned_by?(user)
  end

  def destroy?
    rubygem_owned_by?(user)
  end
end
