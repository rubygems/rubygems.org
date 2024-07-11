class Api::RubygemPolicy < Api::ApplicationPolicy
  class Scope < Api::ApplicationPolicy::Scope
  end

  alias rubygem record

  def index?
    true
  end

  def create?
    true
  end

  def yank?
    true
  end

  def add_owner?
    true
  end

  def remove_owner?
    true
  end

  def show_trusted_publishers?
    api_key_scope?(:configure_trusted_publishers, rubygem) && user_policy!.show_trusted_publishers?
  end
end
