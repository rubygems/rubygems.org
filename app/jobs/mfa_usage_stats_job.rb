class MfaUsageStatsJob < ApplicationJob
  queue_as :default

  def perform
    non_mfa_users = User.where(mfa_level: 0).where.not(id: WebauthnCredential.select(:user_id)).count
    otp_only_users = User.where.not(mfa_level: 0).where.not(id: WebauthnCredential.select(:user_id)).count
    webauthn_only_users = User.where(mfa_level: 0).where(id: WebauthnCredential.select(:user_id)).count
    webauthn_and_otp_users = User.where.not(mfa_level: 0).where(id: WebauthnCredential.select(:user_id)).count

    StatsD.gauge("mfa_usage_stats.non_mfa_users", non_mfa_users)
    StatsD.gauge("mfa_usage_stats.otp_only_users", otp_only_users)
    StatsD.gauge("mfa_usage_stats.webauthn_only_users", webauthn_only_users)
    StatsD.gauge("mfa_usage_stats.webauthn_and_otp_users", webauthn_and_otp_users)
  end
end
