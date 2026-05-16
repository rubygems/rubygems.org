# frozen_string_literal: true

class Avo::Actions::AllowlistEmailDomain < Avo::Actions::ApplicationAction
  self.name = "Allowlist Email Domain"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :index
  }
  self.standalone = true
  self.confirm_button_label = "Allowlist Email Domain"

  def fields
    field :domain, as: :text, required: true,
      help: "The domain to allowlist (e.g., privaterelay.appleid.com). Subdomains will also be allowed."
    field :notes, as: :textarea,
      help: "Optional context for this allowlist entry."
    super
  end

  class ActionHandler < Avo::Actions::ActionHandler
    def handle_standalone
      EmailDomainAllowlist.create!(
        domain: fields["domain"],
        notes: fields["notes"]
      )
    end
  end
end
