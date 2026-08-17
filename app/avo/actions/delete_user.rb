# frozen_string_literal: true

class Avo::Actions::DeleteUser < Avo::Actions::ApplicationAction
  self.name = "Delete User"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view.in?(%i[index show])
  }

  def fields
    field :keep_gems_published, as: :boolean,
      help: "Skip yanking gems for which a selected user is the only owner. Published versions will remain available without an owner."
    super
  end

  self.message = lambda {
    users = record ? "user #{record.display_handle} with #{record.email}" : "#{query.count} selected users"
    owner = record ? "this user is" : "a selected user is"
    "Are you sure you would like to delete #{users}? " \
      "This action can't be undone. By default, gems for which #{owner} the only owner will be yanked. " \
      "Check 'Keep gems published' to preserve those gems as published without an owner."
  }

  self.confirm_button_label = -> { record ? "Delete User" : "Delete Users" }

  def self.blocked_reason
    I18n.t("admin.delete_user.blocked_reason")
  end

  class ActionHandler < Avo::Actions::ActionHandler
    def handle
      @keep_gems_published = ActiveModel::Type::Boolean.new.cast(fields[:keep_gems_published]) == true
      @scheduled_user_count = @blocked_user_count = @failed_user_count = 0

      records.each { |user| process_user(user) }
      add_summary_messages
      redirect_to Avo::Current.view_context.avo.resources_audit_path(@last_audit) if @last_audit
    end

    private

    def process_user(user)
      if user.sole_owner_of_ineligible_gem_versions? && !@keep_gems_published
        @blocked_user_count += 1
        return
      end

      _, @last_audit = in_audited_transaction(
        auditable: user,
        admin_github_user: current_user,
        action: action_name,
        fields:,
        arguments:,
        models: [user]
      ) do
        enqueued_job = DeleteUserJob.perform_later(user:, actor: current_user, keep_gems_published: @keep_gems_published)
        raise ActiveJob::EnqueueError, "DeleteUserJob failed to enqueue" unless enqueued_job

        enqueued_job
      end
      @scheduled_user_count += 1
    rescue StandardError => e
      @failed_user_count += 1
      Rails.error.report(e, handled: true, context: { user_id: user.id })
    end

    def add_summary_messages
      succeed("Account deletion has been scheduled for #{user_count(@scheduled_user_count)}") if @scheduled_user_count.positive?

      issues = []
      if @blocked_user_count.positive?
        issues << "Deletion was not scheduled for #{user_count(@blocked_user_count)}. #{Avo::Actions::DeleteUser.blocked_reason}"
      end
      if @failed_user_count.positive?
        failure_report = @failed_user_count == 1 ? "The failure has" : "The failures have"
        issues << "Deletion could not be scheduled for #{user_count(@failed_user_count)}. #{failure_report} been reported."
      end
      return if issues.empty?

      issue_message = issues.join(" ")
      @scheduled_user_count.positive? ? inform(issue_message) : error(issue_message)
    end

    def user_count(count)
      "#{count} #{'user'.pluralize(count)}"
    end
  end
end
