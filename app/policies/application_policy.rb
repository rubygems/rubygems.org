# frozen_string_literal: true

class ApplicationPolicy
  include SemanticLogger::Loggable

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
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

  private

  delegate :t, to: I18n

  def deny(error = t(:forbidden)) # rubocop:disable Naming/PredicateMethod
    @error = error
    false
  end

  def current_user?(record_user)
    user && user == record_user
  end

  def organization_member_with_role?(user, minimum_role)
    return false unless respond_to?(:organization) && organization.present?
    organization.memberships.where(user: user).with_minimum_role(minimum_role).exists?
  end

  def policy!(user, record) = Pundit.policy!(user, record)
  def user_policy!(record) = policy!(user, record)
end
