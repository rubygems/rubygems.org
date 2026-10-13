# frozen_string_literal: true

class Avo::Actions::RebuildRubygemSearch < Avo::Actions::ApplicationAction
  self.name = "Rebuild Rubygem Search"
  self.message = "Recreate mappings and populate the entire Rubygem search index in the maintenance queue. " \
                 "This is expensive and does not replay concurrent writes. Keep search-data writers paused from before enqueueing " \
                 "until completion and verification; see doc/search-rebuild.md. Monitor the job in /admin/good_job."
  self.visible = lambda {
    Admin::RubygemPolicy.new(current_user, Rubygem).act_on? && view == :index
  }
  self.authorize = lambda {
    Admin::RubygemPolicy.new(current_user, Rubygem).act_on?
  }
  self.standalone = true
  self.confirm_button_label = "Queue full rebuild"

  def fields
    field :maintenance_window, as: :boolean,
      name: "Search-data writers are paused",
      help: "I have arranged a controlled maintenance window and will keep writers paused until verification finishes."
    super
  end

  class ActionHandler < Avo::Actions::ActionHandler
    set_callback :handle, :before do
      unless ActiveModel::Type::Boolean.new.cast(fields[:maintenance_window]) == true
        error "Confirm that search-data writers are paused before rebuilding"
      end
    end

    def handle_standalone
      # Serialize the enqueue check and insert across simultaneous Avo requests.
      ApplicationRecord.advisory_xact_lock!(RebuildRubygemSearchJob.name, 0)
      if (job = RebuildRubygemSearchJob.perform_later)
        succeed("Search rebuild #{job.job_id} queued on maintenance. Monitor /admin/good_job before resuming writers.")
      else
        error "Search rebuild was not queued. Another rebuild may already be queued or running."
      end

      current_user
    end
  end
end
