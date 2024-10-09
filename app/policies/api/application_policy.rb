# frozen_string_literal: true

class Api::ApplicationPolicy
  class Scope
    def initialize(api_key, scope)
      @api_key = api_key
      @scope = scope
    end

    def resolve
      raise NotImplementedError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :api_key, :scope
  end

  attr_reader :user, :record, :error, :api_key

  def initialize(api_key, record)
    @user = api_key.user
    @record = record
    @error = nil
    @api_key = api_key
  end

  def index? = false
  def show? = false
  def create? = false
  def new? = create?
  def update? = false
  def edit? = update?
  def destroy? = false

  private

  delegate :t, to: I18n

  def deny(error)
    @error = error
    false
  end

  def api_policy!(record)
    Pundit.policy!(api_key, [:api, record])
  end

  def user_policy!(record)
    Pundit.policy!(api_key.user, record)
  end

  def api_authorized?(record, action)
    policy = api_policy!(record)
    policy.send(action) || deny(policy.error)
  end

  def user_authorized?(record, action)
    policy = user_policy!(record)
    policy.send(action) || deny(policy.error)
  end

  def api_key_scope?(scope, rubygem = nil)
    api_key.scope?(scope, rubygem) || deny(t(:api_key_insufficient_scope))
  end

  def mfa_requirement_satisfied?(rubygem = nil)
    if rubygem && !rubygem.mfa_requirement_satisfied_for?(user)
      deny t("multifactor_auths.api.mfa_required")
    elsif user&.mfa_required_not_yet_enabled?
      deny t("multifactor_auths.api.mfa_required_not_yet_enabled").chomp
    elsif user&.mfa_required_weak_level_enabled?
      deny t("multifactor_auths.api.mfa_required_weak_level_enabled").chomp
    else
      true
    end
  end

  def user_api_key?
    return true if user
    deny t(:api_key_forbidden)
  end
end
