# frozen_string_literal: true

class Events::UserEvent::OIDCApiKeyRole::AccessPolicyChangedComponent < Events::TableDetailsComponent
  def view_template
    div { t(".role_name", name: additional.name) }
    div { t(".changed_by_admin") } if additional.has_attribute?(:by_owner) && !additional.by_owner
    div { t(".conditions", conditions: additional.conditions.to_sentence) } if additional.conditions.present?
  end
end
