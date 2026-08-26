# frozen_string_literal: true

class Avo::Actions::SyncAdvisories < Avo::Actions::ApplicationAction
  self.name = "Sync Advisories"
  self.message = "Fetch and upsert security advisories from all sources. This runs even when public source flags are off."
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :index
  }
  self.standalone = true
  self.confirm_button_label = "Sync"

  class ActionHandler < Avo::Actions::ActionHandler
    def handle_standalone
      SyncAdvisoriesJob.perform_later(force: true)

      succeed("Advisory sync job scheduled")

      current_user
    end
  end
end
