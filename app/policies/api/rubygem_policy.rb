class Api::RubygemPolicy < Api::ApplicationPolicy
  class Scope < Api::ApplicationPolicy::Scope
  end

  alias rubygem record

  def index?
    api_key_scope?(:index_rubygems)
  end

  def create?
    true
  end

  def yank?
    api_key_scope?(:yank_rubygem, rubygem)
  end

  def add_owner?
    api_key_scope?(:add_owner, rubygem)
  end

  def remove_owner?
    api_key_scope?(:remove_owner, rubygem)
  end

  def configure_trusted_publishers?
    api_key_scope?(:configure_trusted_publishers, rubygem) && user_authorized?(rubygem, :configure_trusted_publishers?)
  end
end
