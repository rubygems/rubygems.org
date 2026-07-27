# frozen_string_literal: true

class Avo::Actions::DeleteUser < Avo::Actions::ApplicationAction
  self.name = "Delete User"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :show
  }

  self.message = lambda {
    "Are you sure you would like to delete user #{record.handle} with #{record.email}? " \
      "This action can't be undone and will use the same account deletion process available from the user's profile."
  }

  self.confirm_button_label = "Delete User"

  class ActionHandler < Avo::Actions::ActionHandler
    def handle_record(user)
      DeleteUserJob.perform_later(user:)
      succeed("Account deletion for #{user.display_handle} has been scheduled")
    end
  end
end
