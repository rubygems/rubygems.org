# frozen_string_literal: true

class Api::WebHookPolicy < Api::ApplicationPolicy
  class Scope < Api::ApplicationPolicy::Scope
  end

  delegate :rubygem, to: :record

  def index?
    account_wide_api_key_scope?(:access_webhooks)
  end

  def create?
    can_access_webhooks?(rubygem)
  end

  # Firing sends a test request and leaves no account state behind, so unlike the
  # other actions a key restricted to a gem is still allowed to do it.
  def fire?
    api_key_scope?(:access_webhooks, rubygem)
  end

  def remove?
    can_access_webhooks?(rubygem)
  end

  private

  def can_access_webhooks?(rubygem)
    return account_wide_api_key_scope?(:access_webhooks) if rubygem.nil?
    api_key_scope?(:access_webhooks, rubygem)
  end
end
