class Api::OIDC::RubygemTrustedPublisherPolicy < Api::ApplicationPolicy
  class Scope < Api::ApplicationPolicy::Scope
  end

  delegate :rubygem, to: :record

  def show?
    can_configure_trusted_publishers? && user_authorized?(record, :show?)
  end

  def create?
    can_configure_trusted_publishers? && user_authorized?(record, :create?)
  end

  def destroy?
    can_configure_trusted_publishers? && user_authorized?(record, :destroy?)
  end

  private

  def can_configure_trusted_publishers?
    api_key_scope?(:configure_trusted_publishers, rubygem)
  end
end
