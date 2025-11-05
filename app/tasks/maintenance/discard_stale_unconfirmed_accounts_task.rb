# frozen_string_literal: true

class Maintenance::DiscardStaleUnconfirmedAccountsTask < MaintenanceTasks::Task
  include SemanticLogger::Loggable

  SECURITY_AUDITING_START_DATE = Time.new(2024, 2, 1).utc
  UNCONFIRMED_USER_RETENTION_DAYS = 30.days

  def collection # rubocop:disable Metrics/MethodLength
    User
      .not_deleted
      .where(email_confirmed: false)
      # only consider users created after we started tracking events
      .where(created_at: SECURITY_AUDITING_START_DATE..UNCONFIRMED_USER_RETENTION_DAYS.ago)
      # owns no gems
      .where("NOT EXISTS (
        SELECT 1 FROM ownerships
        WHERE ownerships.user_id = users.id
        AND ownerships.confirmed_at IS NOT NULL
        LIMIT 1
      )")
      # has never pushed gems
      .where("NOT EXISTS (
        SELECT 1 FROM versions
        WHERE versions.pusher_id = users.id
        LIMIT 1
      )")
      # belongs to no organizations
      .where("NOT EXISTS (
        SELECT 1 FROM memberships
        WHERE memberships.user_id = users.id
        LIMIT 1
      )")
      .where(totp_seed: nil)
      # has never created webauthn credentials
      .where("NOT EXISTS (
        SELECT 1 FROM webauthn_credentials
        WHERE webauthn_credentials.user_id = users.id
        LIMIT 1
      )")
      .where(policies_acknowledged_at: nil)
      # hasn't logged in or changed their password
      .where("
        NOT EXISTS (
          SELECT 1 FROM events_user_events
          WHERE events_user_events.user_id = users.id
          AND events_user_events.tag IN ('user:login:success', 'user:password:changed')
          LIMIT 1
        )
      ")
  end

  def process(user)
    logger.tagged(user_id: user.id, email: user.email) do
      user.transaction do
        user.discard!
      end
    end
  end
end
