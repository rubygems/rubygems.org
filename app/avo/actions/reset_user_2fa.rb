class Avo::Actions::ResetUser2fa < Avo::Actions::ApplicationAction
  self.name = "Reset User 2FA"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :show
  }

  self.message = lambda {
    "Are you sure you would like to disable MFA and reset the password for #{record.handle} #{record.email}?"
  }

  self.confirm_button_label = "Reset MFA"

  class ActionHandler < Avo::Actions::ActionHandler
    def handle_record(user)
      user.disable_totp!
      user.password = SecureRandom.hex(20).encode("UTF-8")
      user.save!
    end
  end
end
