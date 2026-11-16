# frozen_string_literal: true

class Avo::Actions::RemoveOrganizationDomain < Avo::Actions::ApplicationAction
  self.name = "Remove Organization Domain"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :show
  }
  self.message = lambda {
    "Are you sure you would like to remove the domain '#{record.domain}'? " \
      "It will be freed for other organizations; its token and check history are kept."
  }
  self.confirm_button_label = "Remove Domain"

  class ActionHandler < Avo::Actions::ActionHandler
    def handle_record(domain)
      domain.remove!
    end
  end
end
