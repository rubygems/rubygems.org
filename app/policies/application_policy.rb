# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def avo_index?
    false
  end

  def avo_show?
    false
  end

  def avo_create?
    false
  end

  def avo_new?
    avo_create?
  end

  def avo_update?
    false
  end

  def avo_edit?
    avo_update?
  end

  def avo_destroy?
    false
  end

  def admin?
    user.is_a?(Admin::GitHubUser) && user.is_admin
  end

  def belongs_to_team?(slug)
    admin? && user.team_member?(slug)
  end

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
end
