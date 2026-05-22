# frozen_string_literal: true

class Avo::Actions::BlockEmailDomain < Avo::Actions::ApplicationAction
  self.name = "Block Email Domain"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :index
  }
  self.standalone = true
  self.confirm_button_label = "Block Email Domain"

  def fields
    field :domain, as: :text, required: true,
      help: "The domain to block (e.g., disposable.example). Suffix matches will also be blocked."
    field :notes, as: :textarea,
      help: "Optional context for this manual entry."
    super
  end

  class ActionHandler < Avo::Actions::ActionHandler
    def handle_standalone
      BlockedEmailDomain.create!(
        domain: fields["domain"],
        source: :manual,
        notes: fields["notes"]
      )
    end
  end
end
