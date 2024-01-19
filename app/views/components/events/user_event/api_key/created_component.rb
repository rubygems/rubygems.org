# frozen_string_literal: true

class Events::UserEvent::ApiKey::CreatedComponent < Events::TableDetailsComponent
  def template
    div { t(".api_key_name", name: additional.name) }
    div { t(".api_key_scopes", scopes: additional.scopes&.to_sentence) }
    if additional.gem.present?
      div do
        t(".api_key_gem_html", gem: helpers.link_to(additional.gem, rubygem_path(additional.gem)))
      end
    end
    div { t(".api_key_mfa", mfa: additional.mfa ? t(".required") : t(".not_required")) } if additional.has_attribute?(:mfa)
  end
end
