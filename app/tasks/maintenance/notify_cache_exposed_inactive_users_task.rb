# frozen_string_literal: true

class Maintenance::NotifyCacheExposedInactiveUsersTask < MaintenanceTasks::Task
  include SemanticLogger::Loggable

  NOTICE_MAILER_ACTION = "cache_exposure_inactive_notice"
  NOTICE_MAILER_NAME = "cache_exposure_mailer"

  attribute :min_user_id, :integer
  attribute :max_user_id, :integer
  validate :max_user_id_not_before_min

  def collection
    scope = unnotified_inactive_users
    scope = scope.where(id: min_user_id..) if min_user_id.present?
    scope = scope.where(id: ..max_user_id) if max_user_id.present?
    scope
  end

  def process(user)
    logger.tagged(user_id: user.id) do
      CacheExposureMailer.cache_exposure_inactive_notice(user).deliver_later
      logger.info "Queued cache-exposure inactive-key notice"
    end
  end

  private

  def unnotified_inactive_users
    inactive_affected_users.where.not(id: notified_user_ids)
  end

  def inactive_affected_users
    revoked_user_ids = Events::UserEvent
      .where(tag: Events::UserEvent::CACHE_EXPOSURE_KEY_REVOKED)
      .select(:user_id)
    inactive_owner_ids = ApiKey.legacy.expired
      .where.not(owner_id: revoked_user_ids)
      .select(:owner_id)
    User.where(id: inactive_owner_ids).where(blocked_email: nil)
  end

  def notified_user_ids
    Events::UserEvent
      .where(tag: Events::UserEvent::EMAIL_SENT)
      .where("additional ->> 'action' = ?", NOTICE_MAILER_ACTION)
      .where("additional ->> 'mailer' = ?", NOTICE_MAILER_NAME)
      .select(:user_id)
  end

  def max_user_id_not_before_min
    return if min_user_id.blank? || max_user_id.blank?
    return if max_user_id >= min_user_id

    errors.add(:max_user_id, "must be greater than or equal to min_user_id")
  end
end
