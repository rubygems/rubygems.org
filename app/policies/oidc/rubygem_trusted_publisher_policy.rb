class OIDC::RubygemTrustedPublisherPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
  end

  delegate :rubygem, to: :record

  def show?
    rubygem.owned_by?(user)
  end

  def create?
    rubygem.owned_by?(user)
  end

  def destroy?
    rubygem.owned_by?(user)
  end
end
