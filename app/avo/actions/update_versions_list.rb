# frozen_string_literal: true

class Avo::Actions::UpdateVersionsList < Avo::Actions::ApplicationAction
  self.name = "Update Versions List"
  self.message = "Regenerate and upload the compact index versions file used by the /versions endpoint."
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :index
  }
  self.standalone = true
  self.confirm_button_label = "Update"

  class ActionHandler < Avo::Actions::ActionHandler
    def handle_standalone
      UpdateVersionsListJob.perform_later(version: GemInfo::CURRENT_VERSION)

      succeed("Versions list update job scheduled")

      Version.last
    end
  end
end
