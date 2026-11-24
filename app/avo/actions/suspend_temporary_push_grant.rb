# frozen_string_literal: true

class Avo::Actions::SuspendTemporaryPushGrant < Avo::Actions::TemporaryPushGrantAction
  self.name = "Suspend Temporary Push Grant"
  self.message = -> { "Pause publication under grant ##{record.id}? The 72-hour expiry keeps running." }
  self.confirm_button_label = "Suspend"

  class ActionHandler < Avo::Actions::TemporaryPushGrantAction::ActionHandler
    def handle_record(grant)
      grant.suspend!(fields[:comment])
      succeed "Grant ##{grant.id} is suspended"
    end
  end
end
