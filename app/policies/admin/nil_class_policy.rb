class Admin::NilClassPolicy < Admin::ApplicationPolicy
  class Scope < Admin::ApplicationPolicy::Scope
    def resolve
      raise Pundit::NotDefinedError, "Cannot scope NilClass"
    end
  end

  # fallback to parent policy which rejects all actions
end
