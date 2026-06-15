# frozen_string_literal: true

class Avo::Actions::UpdateVersionsList < Avo::Actions::ApplicationAction
  VERSION_SELECTIONS = {
    "1" => [1],
    "2" => [2],
    "both" => [1, 2]
  }.freeze

  self.name = "Update Versions List"
  self.message = "Regenerate and upload the compact index versions file used by the /versions endpoint."
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :index
  }
  self.standalone = true
  self.confirm_button_label = "Update"

  def fields
    field :version, as: :select,
      options: {
        "Both" => "both",
        "V1" => "1",
        "V2" => "2"
      },
      default: "both",
      required: true

    super
  end

  class ActionHandler < Avo::Actions::ActionHandler
    def handle_standalone
      versions.each do |version|
        UpdateVersionsListJob.perform_later(version:)
      end

      succeed("Versions list update job scheduled")

      Version.last
    end

    private

    def versions
      selected = fields["version"]
      normalized = selected&.to_s

      VERSION_SELECTIONS.fetch(normalized) do
        raise ArgumentError, "Unsupported compact index version: #{selected}"
      end
    end
  end
end
