# frozen_string_literal: true

class ApplicationPolicy
  include SemanticLogger::Loggable

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NotImplementedError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :user, :scope
  end

  attr_reader :user, :record, :error

  def initialize(user, record)
    @user = user
    @record = record
    @error = nil
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  def search?
    index?
  end

  private

  delegate :t, to: I18n

  def deny(error = t(:forbidden))
    @error = error
    false
  end

  def allow
    @error = nil
    true
  end

  def current_user?(record_user)
    user && user == record_user
  end

  def rubygem_owned_by?(user)
    rubygem.owned_by?(user) || deny(t(:forbidden))
  end

  def rubygem_owned_by_with_role?(user, minimum_required_role:)
    rubygem.owned_by_with_role?(user, minimum_required_role) || deny(t(:forbidden))
  end

  def policy!(user, record) = Pundit.policy!(user, record)
  def user_policy!(record) = policy!(user, record)

  def user_authorized?(record, action)
    policy = user_policy!(record)
    policy.send(action) || deny(policy.error)
  end
end
