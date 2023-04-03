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
      security_user = User.find_by!(email: "security@rubygems.org")
      versions_to_yank = version_id == OPTION_ALL ? rubygem.versions : rubygem.versions.where(id: version_id)

      versions_to_yank.each do |version|
        security_user.deletions.create!(version: version) unless version.yanked?
      end
    end
  end
end
