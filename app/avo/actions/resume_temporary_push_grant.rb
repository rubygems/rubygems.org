# frozen_string_literal: true

class Avo::Actions::ResumeTemporaryPushGrant < Avo::Actions::TemporaryPushGrantAction
  self.name = "Resume Temporary Push Grant"
  self.message = -> { "Resume publication under grant ##{record.id} until its original expiry?" }
  self.confirm_button_label = "Resume"

  class ActionHandler < Avo::Actions::TemporaryPushGrantAction::ActionHandler
    def handle_record(grant)
      grant.resume!
      succeed "Grant ##{grant.id} is active until #{grant.expires_at.utc.iso8601}"
    end
  end
end
