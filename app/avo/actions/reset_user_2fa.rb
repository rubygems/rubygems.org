class ResetUser2fa < BaseAction
  self.name = "Reset User 2FA"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :show
  }

  self.message = lambda {
    "Are you sure you would like to disable MFA and reset the password for #{record.handle} #{record.email}?"
  }

  self.confirm_button_label = "Reset MFA"

  class ActionHandler < ActionHandler
    def handle_model(user)
      user.disable_totp!
      user.password = SecureRandom.hex(20).encode("UTF-8")
      user.save!
    end
  end
end
