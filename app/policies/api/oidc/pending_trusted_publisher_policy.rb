# frozen_string_literal: true

class Api::OIDC::PendingTrustedPublisherPolicy < Api::ApplicationPolicy
  class Scope < Api::ApplicationPolicy::Scope
    def initialize(api_key, scope) # rubocop:disable Lint/MissingSuper
      @api_key = api_key
      @scope = scope
    end

    def resolve
      scope.where(user: api_key.user)
    end
  end

  def index?
    user_api_key? &&
      account_scoped_key? &&
      api_key_scope?(:configure_trusted_publishers)
  end

  def create?
    user_api_key? &&
      mfa_requirement_satisfied? &&
      account_scoped_key? &&
      api_key_scope?(:configure_trusted_publishers)
  end

  private

  # Pending publishers are for not-yet-existing gems, so a gem-restricted key
  # has no meaningful gem to bind to and must not register arbitrary names.
  def account_scoped_key?
    return true unless api_key.rubygem
    deny t(:api_key_insufficient_scope)
  end
end
