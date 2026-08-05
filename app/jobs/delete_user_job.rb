# frozen_string_literal: true

class DeleteUserJob < ApplicationJob
  queue_as :default
  queue_with_priority PRIORITIES.fetch(:profile_deletion)

  def perform(user:, send_emails: true)
    email = user.email
    return if user.discarded?
    send_emails ? user.discard! : user.discard_without_deletion_email!
  rescue ActiveRecord::ActiveRecordError, Discard::RecordNotDiscarded => e
    # Catch the exception so we can log it, otherwise using `destroy` would give
    # us no hint as to why the deletion failed.
    Rails.error.report(e, context: { user: user.as_json, email: }, handled: true)
    Mailer.deletion_failed(email).deliver_later if send_emails
  end
end
