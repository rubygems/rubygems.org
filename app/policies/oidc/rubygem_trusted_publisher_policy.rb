class OIDC::RubygemTrustedPublisherPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
  end

  delegate :rubygem, to: :record

  def show?
    permissions.can_manage_owners? || deny
  end

  def create?
    permissions.can_manage_owners? || deny
  end

  def destroy?
    permissions.can_manage_owners? || deny
  end

  private

  def permissions
    GemPermissions.new(rubygem, user)
  end
end
