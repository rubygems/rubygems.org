# frozen_string_literal: true

class Avo::Actions::YankRubygemsForUser < Avo::Actions::ApplicationAction
  self.name = "Yank all Rubygems"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") &&
      view == :show &&
      resource.record.rubygems.present?
  }

  self.message = lambda {
    "Are you sure you would like to yank all rubygems for user #{record.handle} with #{record.email}?"
  }

  self.confirm_button_label = "Yank all Rubygems"

  class ActionHandler < Avo::Actions::ActionHandler
    def handle_record(user)
      YankRubygemsForUserJob.perform_later(user: user)
      succeed("Yanking all rubygems for #{user.handle} has been scheduled")
    end
  end
end
