class Api::RubygemPolicy < Api::ApplicationPolicy
  class Scope < Api::ApplicationPolicy::Scope
  end

  alias rubygem record

  def show_trusted_publishers?
    api_key_scope?(:configure_trusted_publishers, rubygem) && user_policy!.show_trusted_publishers?
  end
end
