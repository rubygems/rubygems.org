# frozen_string_literal: true

class Avo::Actions::RevokeTemporaryPushGrant < Avo::Actions::TemporaryPushGrantAction
  self.name = "Revoke Temporary Push Grant"
  self.message = lambda {
    "Revoke grant ##{record.id} and expire its API key? Already published releases are not yanked."
  }
  self.confirm_button_label = "Revoke"

  class ActionHandler < Avo::Actions::TemporaryPushGrantAction::ActionHandler
    def handle_record(grant)
      grant.revoke!(fields[:comment])
      succeed "Grant ##{grant.id} is revoked"
    end
  end
end
