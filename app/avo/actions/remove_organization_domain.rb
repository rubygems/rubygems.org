# frozen_string_literal: true

class Avo::Actions::RemoveOrganizationDomain < Avo::Actions::ApplicationAction
  self.name = "Remove Organization Domain"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :show
  }
  self.message = lambda {
    "Are you sure you would like to remove the domain '#{record.domain}'? " \
      "It and its check history will be deleted and the domain freed for other organizations."
  }
  self.confirm_button_label = "Remove Domain"

  class ActionHandler < Avo::Actions::ActionHandler
    def handle_record(domain)
      domain.remove!(actor: current_user)
    end
  end
end
