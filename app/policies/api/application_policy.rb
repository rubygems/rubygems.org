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

  attr_reader :api_key, :record

  def initialize(api_key, record)
    @api_key = api_key
    @user = api_key.user
    @record = record
  end

  def index? = false
  def show? = false
  def create? = false
  def new? = create?
  def update? = false
  def edit? = update?
  def destroy? = false

  private

  def policy!(user, record) = Pundit.policy!(user, record)
  def user_policy! = policy!(api_key.user, record)
  def api_key_scope?(...) = api_key.scope?(...)
end
