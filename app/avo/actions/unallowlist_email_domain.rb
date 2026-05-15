# frozen_string_literal: true

class Avo::Actions::UnallowlistEmailDomain < Avo::Actions::ApplicationAction
  self.name = "Remove from Allowlist"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :show
  }
  self.message = lambda {
    "Are you sure you would like to remove '#{resource.record.domain}' from the allowlist?"
  }
  self.confirm_button_label = "Remove from Allowlist"

  class ActionHandler < Avo::Actions::ActionHandler
    def handle_record(email_domain_allowlist)
      email_domain_allowlist.destroy!
    end
  end
end
