class Api::RubygemPolicy < Api::ApplicationPolicy
  class Scope < Api::ApplicationPolicy::Scope
  end

  alias rubygem record

  def index?
    true
  end

  def create?
    mfa_requirement_satisfied?
  end

  def yank?
    user_api_key? &&
      mfa_requirement_satisfied?(rubygem)
  end

  def add_owner?
    user_api_key? &&
      mfa_requirement_satisfied?(rubygem)
  end

  def remove_owner?
    user_api_key? &&
      mfa_requirement_satisfied?(rubygem)
  end

  def show_trusted_publishers?
    user_api_key? &&
      mfa_requirement_satisfied?(rubygem)
      api_key_scope?(:configure_trusted_publishers, rubygem) &&
      user_authorized?(rubygem, :show_trusted_publishers?)
  end
end
