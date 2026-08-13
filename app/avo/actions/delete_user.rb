# frozen_string_literal: true

class Avo::Actions::DeleteUser < Avo::Actions::ApplicationAction
  self.name = "Delete User"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :show
  }

  def fields
    field :keep_gems_published, as: :boolean,
      help: "Skip yanking gems for which this user is the only owner. Published versions will remain available without an owner."
    super
  end

  self.message = lambda {
    "Are you sure you would like to delete user #{record.display_handle} with #{record.email}? " \
      "This action can't be undone. By default, gems for which this user is the only owner will be yanked."
  }

  self.confirm_button_label = "Delete User"

  def self.blocked_reason
    I18n.t("admin.delete_user.blocked_reason")
  end

  class ActionHandler < Avo::Actions::ActionHandler
    def handle_record(user)
      keep_gems_published = ActiveModel::Type::Boolean.new.cast(fields[:keep_gems_published]) == true
      return error(Avo::Actions::DeleteUser.blocked_reason) if user.sole_owner_of_ineligible_gem_versions? && !keep_gems_published

      DeleteUserJob.perform_later(user:, actor: current_user, keep_gems_published:)
      succeed("Account deletion for #{user.display_handle} has been scheduled")
    end
  end
end
