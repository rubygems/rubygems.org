class Avo::Actions::BlockUser < Avo::Actions::ApplicationAction
  self.name = "Block User"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :show
  }

  self.message = lambda {
    "Are you sure you would like to block user #{record.handle} with #{record.email}?"
  }

  self.confirm_button_label = "Block User"

  class ActionHandler < Avo::Actions::ActionHandler
    def handle_record(user)
      user.block!
    end
  end
end
