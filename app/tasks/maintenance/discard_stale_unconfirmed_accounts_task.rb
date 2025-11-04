# frozen_string_literal: true

class Maintenance::DiscardStaleUnconfirmedAccountsTask < MaintenanceTasks::Task
  include SemanticLogger::Loggable

  UNCONFIRMED_USER_RETENTION_DAYS = 30.days

  def collection
    User
      .not_deleted
      .where(email_confirmed: false)
      .where(created_at: ...UNCONFIRMED_USER_RETENTION_DAYS.ago)
  end

  def process(user)
    logger.tagged(user_id: user.id, email: user.email) do
      user.transaction do
        user.discard!
      end
    end
  end
end
