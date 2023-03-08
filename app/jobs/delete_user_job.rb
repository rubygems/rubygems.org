class DeleteUserJob < ApplicationJob
  queue_as :default
  queue_with_priority PRIORITIES.fetch(:profile_deletion)

  def perform(user:)
    email = user.email
    if user.destroy
      Mailer.deletion_complete(email).deliver_later
    else
      Mailer.deletion_failed(email).deliver_later
    end
  end
end
