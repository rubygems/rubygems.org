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

  attr_reader :api_key, :record, :error

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

  def user_policy!(record)
    Pundit.policy!(api_key.user, record)
  end

  def user_authorized?(record, action)
    policy = user_policy!(record)
    policy.send(action) || deny(policy.error)
  end

  def api_key_scope?(scope, rubygem = nil)
    rubygem = nil unless rubygem.is_a?(Rubygem)
    api_key.scope?(scope, rubygem) || deny(t(:api_key_insufficient_scope))
  end
end
