# frozen_string_literal: true

class Avo::Actions::SyncAdvisories < Avo::Actions::ApplicationAction
  self.name = "Sync Advisories"
  self.message = "Fetch and upsert security advisories from the selected source. This runs even when the public source flag is off."
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :index
  }
  self.standalone = true
  self.confirm_button_label = "Sync"

  def fields
    field :source, as: :select,
      options: -> { Advisory::SOURCES.to_h { |klass| [klass.name.demodulize, klass.sti_name] } },
      required: true,
      help: "Which advisory source to fetch."
    super
  end

  class ActionHandler < Avo::Actions::ActionHandler
    set_callback :handle, :before do
      error "Unknown advisory source" unless Advisory::SOURCES.map(&:sti_name).include?(fields[:source])
    end

    def handle_standalone
      SyncAdvisoriesJob.perform_later(source: fields[:source], force: true)

      succeed("Advisory sync job scheduled")

      current_user
    end
  end
end
