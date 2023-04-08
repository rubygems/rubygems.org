class YankUser < BaseAction
  self.name = "Yank User"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :show
  }
  self.message = lambda {
    "Are you sure you would like to yank user #{record.handle} #{record.email}?"
  }
  self.confirm_button_label = "Yank User"

  class ActionHandler < ActionHandler
    def handle_model(user)
      rubygems = user.rubygems

      rubygems.find_each(&:yank_versions!)
      user.block!
    end
  end
end
