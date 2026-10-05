# frozen_string_literal: true

class Avo::Actions::YankRubygem < Avo::Actions::ApplicationAction
  OPTION_ALL = "All"

  def fields
    # On the index view with several gems selected there is no single record,
    # so only "All" (every version of each selected gem) is offered.
    field :version, as: :select,
      options: -> { [OPTION_ALL] + (record ? record.versions.indexed.pluck(:number, :id) : []) },
      help: "Select Version which needs to be yanked."
    super
  end

  self.name = "Yank Rubygem"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") &&
      (view == :index || (view == :show && resource.record.versions.indexed.present?))
  }
  self.authorize = lambda {
    Admin::RubygemPolicy.new(current_user, Rubygem).act_on?
  }

  self.message = lambda {
    if record
      "Are you sure you would like to yank gem #{record.name}?"
    else
      "Are you sure you would like to yank all versions of #{query ? "#{query.count} selected gems" : 'the selected gems'}?"
    end
  }

  self.confirm_button_label = "Yank Rubygem"

  class ActionHandler < Avo::Actions::ActionHandler
    # Bound bulk yanks to one index page so "Select all matching" can't yank an
    # unbounded set synchronously.
    set_callback :handle, :before do
      max = Avo.configuration.per_page_steps.max
      error "Select at most #{max} gems to yank at once" if records.size > max
    end

    def handle_record(rubygem)
      version_id = fields["version"]
      version_id_to_yank = version_id if version_id != OPTION_ALL

      rubygem.yank_versions!(version_id: version_id_to_yank, force: true)
    end
  end
end
