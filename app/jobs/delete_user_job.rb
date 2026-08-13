# frozen_string_literal: true

class DeleteUserJob < ApplicationJob
  queue_as :default
  queue_with_priority PRIORITIES.fetch(:profile_deletion)

  def perform(user:, actor:, keep_gems_published: false)
    email = user.email
    return if user.discarded?
    user.delete_account!(keep_gems_published:)
    Mailer.deletion_complete(email).deliver_later if self_service_deletion?(user, actor)
  rescue ActiveRecord::ActiveRecordError, Discard::RecordNotDiscarded => e
    # Catch the exception so we can log it, otherwise using `destroy` would give
    # us no hint as to why the deletion failed.
    Rails.error.report(e, context: { user: user.as_json, email: }, handled: true)
    Mailer.deletion_failed(email).deliver_later if self_service_deletion?(user, actor)
  end

  private

  def self_service_deletion?(user, actor)
    user == actor
  end
end
