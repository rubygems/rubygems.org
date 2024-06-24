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

  attr_reader :user, :record

  def initialize(user, record)
    case user
    when ApiKey
      @user = PunditApiKey.new(user)
    when User
      @user = PunditUser.new(user)
    when nil
      @user = nil
    else
      raise ArgumentError, "Invalid user type: #{user.class}"
    end
    @record = record
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

  def api_key?
    @api_key.present?
  end

  def rubygem
    record.rubygem
  end

  def gem_owner?
    user&.owns_gem?(rubygem)
  end

  def same_user?(record_user)
    user.same_user?(record_user)
  end
end
