# frozen_string_literal: true

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
