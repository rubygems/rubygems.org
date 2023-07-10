class MfaUsageStatsJob < ApplicationJob
  queue_as "stats"

  def perform
    non_mfa_users = User.where(totp_seed: nil).where.not(id: WebauthnCredential.select(:user_id)).count
    totp_only_users = User.where.not(totp_seed: nil).where.not(id: WebauthnCredential.select(:user_id)).count
    webauthn_only_users = User.where(totp_seed: nil).where(id: WebauthnCredential.select(:user_id)).count
    webauthn_and_totp_users = User.where.not(totp_seed: nil).where(id: WebauthnCredential.select(:user_id)).count

    StatsD.gauge("mfa_usage_stats.non_mfa_users", non_mfa_users)
    StatsD.gauge("mfa_usage_stats.totp_only_users", totp_only_users)
    StatsD.gauge("mfa_usage_stats.webauthn_only_users", webauthn_only_users)
    StatsD.gauge("mfa_usage_stats.webauthn_and_totp_users", webauthn_and_totp_users)
  end
end
