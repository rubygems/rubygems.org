class UnblockUser < BaseAction
  self.name = "Block User"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :show
  }

  self.message = lambda {
    "Are you sure you would like to unblock user #{record.handle} with #{record.blocked_email}?"
  }

  self.confirm_button_label = "Unblock User"

  class ActionHandler < ActionHandler
    def handle_model(user)
      user.unblock!
    end
  end
end
