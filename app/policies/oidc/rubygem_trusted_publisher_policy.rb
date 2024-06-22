class OIDC::RubygemTrustedPublisherPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.none
    end
  end

  def show?
    record.rubygem.owned_by?(user)
  end

  def create?
    record.rubygem.owned_by?(user)
  end

  def destroy?
    record.rubygem.owned_by?(user)
  end
end
