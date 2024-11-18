class Api::WebHookPolicy < Api::ApplicationPolicy
  class Scope < Api::ApplicationPolicy::Scope
  end

  delegate :rubygem, to: :record

  def index?
    can_access_webhooks?
  end

  def create?
    can_access_webhooks?(rubygem)
  end

  def fire?
    can_access_webhooks?(rubygem)
  end

  def remove?
    can_access_webhooks?(rubygem)
  end

  private

  def can_access_webhooks?(rubygem = nil)
    api_key_scope?(:access_webhooks, rubygem)
  end
end
