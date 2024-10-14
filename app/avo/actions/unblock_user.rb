class Avo::Actions::UnblockUser < Avo::Actions::ApplicationAction
  self.name = "Unblock User"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :show && record.blocked?
  }

  self.message = lambda {
    "Are you sure you would like to unblock user #{record.handle} with #{record.blocked_email}?"
  }

  self.confirm_button_label = "Unblock User"

  class ActionHandler < Avo::Actions::ActionHandler
    def handle_record(user)
      user.unblock!
    end
  end
end
