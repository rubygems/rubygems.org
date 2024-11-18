class Api::RubygemPolicy < Api::ApplicationPolicy
  class Scope < Api::ApplicationPolicy::Scope
  end

  alias rubygem record

  def index?
    api_key_scope?(:index_rubygems)
  end

  def create?
    mfa_requirement_satisfied? &&
      api_key_scope?(:push_rubygem)
  end

  def yank?
    user_api_key? &&
      mfa_requirement_satisfied?(rubygem) &&
      api_key_scope?(:yank_rubygem, rubygem)
  end

  def add_owner?
    user_api_key? &&
      mfa_requirement_satisfied?(rubygem) &&
      api_key_scope?(:add_owner, rubygem) &&
      user_authorized?(rubygem, :add_owner?)
  end

  def update_owner?
    user_api_key? &&
      mfa_requirement_satisfied?(rubygem) &&
      api_key_scope?(:update_owner, rubygem) &&
      user_authorized?(rubygem, :update_owner?)
  end

  def remove_owner?
    user_api_key? &&
      mfa_requirement_satisfied?(rubygem) &&
      api_key_scope?(:remove_owner, rubygem) &&
      user_authorized?(rubygem, :remove_owner?)
  end

  def configure_trusted_publishers?
    user_api_key? &&
      mfa_requirement_satisfied?(rubygem) &&
      api_key_scope?(:configure_trusted_publishers, rubygem) &&
      user_authorized?(rubygem, :configure_trusted_publishers?)
  end
end
