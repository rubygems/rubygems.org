# frozen_string_literal: true

# Since #6881 email confirmation and password reset tokens live in digest
# columns; users.confirmation_token and users.token_expires_at are only ever
# written as nil. Clear the values left on older rows, including deleted users.
class Maintenance::ClearLegacyEmailConfirmationTokensTask < MaintenanceTasks::Task
  include SemanticLogger::Loggable

  def collection
    legacy_tokens(User.unscoped)
  end

  def process(user)
    cleared = legacy_tokens(User.unscoped.where(id: user.id))
      .update_all(confirmation_token: nil, token_expires_at: nil)

    logger.info("Cleared legacy email confirmation token", user_id: user.id) if cleared.positive?
  end

  private

  def legacy_tokens(scope)
    scope.where.not(confirmation_token: nil).or(scope.where.not(token_expires_at: nil))
  end
end
