class YankRubygem < BaseAction
  OPTION_ALL = "All".freeze

  field :version, as: :select,
    options: lambda { |model:, resource:, view:, field:| # rubocop:disable Lint/UnusedBlockArgument
      [OPTION_ALL] + model.versions.indexed.pluck(:number, :id)
    },
    help: "Select Version which needs to be yanked."

  self.name = "Yank Rubygem"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") &&
      view == :show &&
      resource.model.versions.indexed.present?
  }

  self.message = lambda {
    "Are you sure you would like to yank gem #{record.name}?"
  }

  self.confirm_button_label = "Yank Rubygem"

  class ActionHandler < ActionHandler
    def handle_model(rubygem)
      version_id = fields["version"]
      version_id_to_yank = version_id if version_id != OPTION_ALL

      rubygem.yank_versions!(version_id: version_id_to_yank)
    end
  end
end
