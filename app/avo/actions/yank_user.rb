# frozen_string_literal: true

class Avo::Actions::YankUser < Avo::Actions::ApplicationAction
  self.name = "Yank User"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :show
  }
  self.message = lambda {
    "Are you sure you would like to yank user #{record.handle} #{record.email}? It will block user and yank all associated rubygems"
  }
  self.confirm_button_label = "Yank User"

  class ActionHandler < Avo::Actions::ActionHandler
    def handle_record(user)
      YankRubygemsForUserJob.perform_later(user: user)
      user.block!
    end
  end
end
