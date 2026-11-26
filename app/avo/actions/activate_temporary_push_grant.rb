# frozen_string_literal: true

class Avo::Actions::ActivateTemporaryPushGrant < Avo::Actions::TemporaryPushGrantAction
  self.name = "Activate Temporary Push Grant"
  self.message = lambda {
    "Issue a publish-only API key to #{record.grantee.handle} for #{record.rubygem.name} #{record.version}? " \
      "It expires #{record.correction? ? 'with the original grant' : '72 hours from now'} " \
      "and is emailed to #{record.grantee.email}."
  }
  self.confirm_button_label = "Activate and issue key"

  class ActionHandler < Avo::Actions::TemporaryPushGrantAction::ActionHandler
    def handle_record(grant)
      grant.activate!
      succeed "Grant ##{grant.id} is active until #{grant.expires_at.utc.iso8601}. " \
              "The API key was emailed to #{grant.grantee.handle}."
    end
  end
end
