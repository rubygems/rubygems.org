class Avo::Actions::ResetUser2fa < Avo::Actions::ApplicationAction
  self.name = "Reset User 2FA"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :show
  }

  self.message = lambda {
    "Are you sure you would like to disable MFA, WebAuthn devices, and reset the password for #{record.handle} #{record.email}?"
  }

  self.confirm_button_label = "Reset MFA"

  class ActionHandler < Avo::Actions::ActionHandler
    def handle_record(user)
      user.disable_totp! if user.totp_enabled?
      user.webauthn_credentials.destroy_all if user.webauthn_enabled?
      user.reset_mfa_attributes

      user.password = SecureRandom.hex(20).encode("UTF-8")
      user.save!
    end
  end
end
