class DeleteUserJob < ApplicationJob
  queue_as :default
  queue_with_priority PRIORITIES.fetch(:profile_deletion)

  def perform(user:)
    email = user.email
    user.destroy!
  rescue ActiveRecord::RecordNotDestroyed, ActiveRecord::NotNullViolation, ActiveRecord::DeleteRestrictionError => e
    # Catch the exception so we can log it, otherwise using `destroy` would give
    # us no hint as to why the deletion failed.
    Rails.error.report(e, context: { user:, email: }, handled: true)
    Mailer.deletion_failed(email).deliver_later
  else
    Mailer.deletion_complete(email).deliver_later
  end
end
