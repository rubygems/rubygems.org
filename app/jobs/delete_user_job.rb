# frozen_string_literal: true

class DeleteUserJob < ApplicationJob
  queue_as :default
  queue_with_priority PRIORITIES.fetch(:profile_deletion)

  def perform(user:, initiated_by:)
    notify_user = notify_user?(initiated_by)
    email = user.email
    return if user.discarded?
    user.discard!
    Mailer.deletion_complete(email).deliver_later if notify_user
  rescue ActiveRecord::ActiveRecordError, Discard::RecordNotDiscarded => e
    # Catch the exception so we can log it, otherwise using `destroy` would give
    # us no hint as to why the deletion failed.
    Rails.error.report(e, context: { user: user.as_json, email: }, handled: true)
    Mailer.deletion_failed(email).deliver_later if notify_user
  end

  private

  def notify_user?(initiated_by)
    case initiated_by.to_sym
    when :user then true
    when :admin then false
    else raise ArgumentError, "Unknown deletion initiator: #{initiated_by.inspect}"
    end
  end
end
