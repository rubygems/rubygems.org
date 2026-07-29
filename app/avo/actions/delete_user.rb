# frozen_string_literal: true

class Avo::Actions::DeleteUser < Avo::Actions::ApplicationAction
  self.name = "Delete User"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :show
  }

  self.message = lambda {
    "Are you sure you would like to delete user #{record.handle} with #{record.email}? " \
      "This action can't be undone and will use the same account deletion process available from the user's profile."
  }

  self.confirm_button_label = "Delete User"

  def self.blocked_reason
    I18n.t("admin.delete_user.blocked_reason")
  end

  def enabled?
    super && !blocked?
  end

  def action_name
    return super unless blocked?

    "#{super} — #{self.class.blocked_reason}"
  end

  class ActionHandler < Avo::Actions::ActionHandler
    def handle_record(user)
      return error(Avo::Actions::DeleteUser.blocked_reason) if user.sole_owner_of_old_gem_versions?

      DeleteUserJob.perform_later(user:)
      succeed("Account deletion for #{user.display_handle} has been scheduled")
    end
  end

  private

  def blocked?
    return @blocked if defined?(@blocked)

    @blocked = record.sole_owner_of_old_gem_versions?
  end
end
