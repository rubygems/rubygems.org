class YankUser < BaseAction
  self.name = "Yank User"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :show
  }
  self.message = lambda {
    "Are you sure you would like to yank user #{record.handle} #{record.email}? It will block user and yank all associated rubygems"
  }
  self.confirm_button_label = "Yank User"

  class ActionHandler < ActionHandler
    def handle_model(user)
      user.rubygems.find_each do |rubygem|
        rubygem.yank_versions!(force: true)
      end
      user.block!
    end
  end
end
