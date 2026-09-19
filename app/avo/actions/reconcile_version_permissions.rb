# frozen_string_literal: true

class Avo::Actions::ReconcileVersionPermissions < Avo::Actions::ApplicationAction
  self.name = "Reconcile version permissions"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") &&
      view == :show &&
      resource.record.deletion.blank?
  }
  self.message = lambda {
    "Are you sure you would like to reconcile S3 permissions for #{record.full_name} and purge Fastly?"
  }
  self.confirm_button_label = "Reconcile permissions"

  class ActionHandler < Avo::Actions::ActionHandler
    def handle_record(version)
      paths(version).each do |path|
        RubygemFs.instance.reconcile_permissions(path)
        FastlyPurgeJob.perform_later(path:, soft: false)
      end
    end

    private

    def paths(version)
      [
        "gems/#{version.gem_file_name}",
        "quick/Marshal.4.8/#{version.full_name}.gemspec.rz"
      ]
    end
  end
end
