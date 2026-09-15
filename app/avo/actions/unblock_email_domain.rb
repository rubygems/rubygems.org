# frozen_string_literal: true

class Avo::Actions::UnblockEmailDomain < Avo::Actions::ApplicationAction
  self.name = "Unblock Email Domain"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :show && resource.record.manual?
  }
  self.message = lambda {
    "Are you sure you would like to remove '#{resource.record.domain}' from the blocklist?"
  }
  self.confirm_button_label = "Unblock Email Domain"

  class ActionHandler < Avo::Actions::ActionHandler
    def handle_record(blocked_email_domain)
      raise "Refusing to unblock upstream-sourced row" if blocked_email_domain.upstream?
      blocked_email_domain.destroy!
    end
  end
end
