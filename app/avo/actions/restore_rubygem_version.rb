class RestoreRubygemVersion < BaseAction
  field :version_with_platform, as: :select,
    options: lambda { |model:, resource:, view:, field:| # rubocop:disable Lint/UnusedBlockArgument
      Deletion.where(rubygem: model.name).map do |deletion|
        ["version:#{deletion.number} - platform:#{deletion.platform}", deletion.id]
      end
    }, help: "Select version with platform which needs to be restored."

  self.name = "Restore version"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") &&
      view == :show &&
      Deletion.where(rubygem: resource.model.name).present?
  }

  self.message = lambda {
    "Are you sure you would like to restore #{record.name} with "
  }

  self.confirm_button_label = "Restore version"

  class ActionHandler < ActionHandler
    def handle_model(rubygem)
      deletion_id = fields["version_with_platform"]

      Deletion.where(rubygem: rubygem.name, id: deletion_id).each do |deletion|
        deletion.version = rubygem.find_version!(number: deletion.number, platform: deletion.platform)
        deletion.restore!
      end
    end
  end
end
