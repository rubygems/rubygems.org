# frozen_string_literal: true

# Permanently deletes an organization domain and its check history. The
# organization:domain:deleted event and this action's audit keep the domain and
# its TXT value for reference.
class Avo::Actions::DeleteOrganizationDomain < Avo::Actions::ApplicationAction
  self.name = "Delete Organization Domain"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :show
  }
  self.message = lambda {
    "Are you sure you would like to delete the domain '#{record.domain}'? " \
      "It and its check history will be permanently deleted and the domain freed for other organizations. " \
      "The domain and its TXT value stay in the audit trail."
  }
  self.confirm_button_label = "Delete Domain"

  class ActionHandler < Avo::Actions::ActionHandler
    def handle_record(domain)
      domain.destroy_with_audit!(actor: current_user)
    end
  end
end
