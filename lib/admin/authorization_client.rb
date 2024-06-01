# This class is the same as the default pundit authorization client.
# It just adds the admin scope automatically so that Avo pundit policies can be kept separate.
class Admin::AuthorizationClient < Avo::Services::AuthorizationClients::PunditClient
  def authorize(user, record, action, policy_class: nil)
    # After https://github.com/avo-hq/avo/pull/2827 lands, we can hopefully remove this hack
    policy_class ||= Admin::GitHubUserPolicy if record == Admin::GitHubUser
    super(user, [:admin, record], action, policy_class: policy_class)
  end

  def policy(user, record)
    super(user, [:admin, record])
  end

  def policy!(user, record)
    super(user, [:admin, record])
  end

  def apply_policy(user, model, policy_class: nil)
    # Try and figure out the scope from a given policy or auto-detected one
    scope_from_policy_class = scope_for_policy_class(policy_class)

    # If we discover one use it.
    # Else fallback to pundit.
    if scope_from_policy_class.present?
      scope_from_policy_class.new(user, model).resolve
    else
      Pundit.policy_scope!(user, [:admin, model])
    end
  rescue Pundit::NotDefinedError => e
    raise Avo::NoPolicyError, e.message
  end

  private

  # Fetches the scope for a given policy
  def scope_for_policy_class(policy_class = nil)
    return if policy_class.blank?

    return unless policy_class.present? && defined?(Admin.const_get(policy_class.to_s)&.const_get("Scope"))
    policy_class::Scope
  end
end
