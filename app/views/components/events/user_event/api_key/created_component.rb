# frozen_string_literal: true

class Events::UserEvent::ApiKey::CreatedComponent < Events::TableDetailsComponent
  def view_template
    div { t(".api_key_name", name: additional.name) }
    div { t(".api_key_scopes", scopes: additional.scopes&.to_sentence) }
    raw t(".api_key_gem_html", gem: view_context.link_to(additional.gem, rubygem_path(additional.gem))) if additional.gem.present?
    if additional.organization.present?
      raw t(".api_key_organization_html",
        organization: view_context.link_to(additional.organization, organization_path(additional.organization)))
    end
    div { t(".api_key_mfa", mfa: additional.mfa ? t(".required") : t(".not_required")) } if additional.has_attribute?(:mfa)
  end
end
