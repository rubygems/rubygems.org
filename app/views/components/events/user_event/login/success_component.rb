# frozen_string_literal: true

class Events::UserEvent::Login::SuccessComponent < Events::TableDetailsComponent
  def view_template
    if additional.authentication_method == "webauthn"
      plain t(".webauthn_login", device: additional.two_factor_label)
    elsif additional.two_factor_method.blank?
      plain t(".mfa_method", method: t(".none"))
    elsif additional.two_factor_method == "webauthn"
      plain t(".mfa_method", method: "WebAuthn")
      br
      plain t(".mfa_device", device: additional.two_factor_label)
    else
      plain t(".mfa_method", method: additional.two_factor_method)
    end
  end
end
