# frozen_string_literal: true

class Events::UserEvent::Password::CompromisedComponent < Events::TableDetailsComponent
  def view_template
    plain t(".mfa_status", status: additional.mfa_enabled ? t(".mfa_enabled") : t(".mfa_disabled"))
    br
    plain t(".action_taken", action: additional.action_taken.humanize)
  end
end
