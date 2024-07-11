class Api::WebHookPolicy < Api::ApplicationPolicy
  class Scope < Api::ApplicationPolicy::Scope
  end

  def index?
    true
  end

  def create?
    true
  end

  def fire?
    true
  end

  def remove?
    true
  end
end
