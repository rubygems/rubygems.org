require "test_helper"

class MfaUsageStatsJobTest < ActiveJob::TestCase
  include StatsD::Instrument::Assertions

  setup do
    create(:user) # non-mfa user
    2.times { create(:user).enable_totp!(ROTP::Base32.random_base32, :ui_and_api) } # otp-only users
    3.times { create(:webauthn_credential, user: create(:user)) } # webauthn-only users
    # webauthn-and-otp users
    4.times do
      user = create(:user)
      user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
      create(:webauthn_credential, user: user)
    end
  end

  test "it sends the count of non-MFA users to statsd" do
    assert_statsd_gauge("mfa_usage_stats.non_mfa_users", 1) do
      MfaUsageStatsJob.perform_now
    end
  end

  test "it sends the count of OTP-only users to statsd" do
    assert_statsd_gauge("mfa_usage_stats.totp_only_users", 2) do
      MfaUsageStatsJob.perform_now
    end
  end

  test "it sends the count of WebAuthn-only users to statsd" do
    assert_statsd_gauge("mfa_usage_stats.webauthn_only_users", 3) do
      MfaUsageStatsJob.perform_now
    end
  end

  test "it sends the count of WebAuthn-and-OTP users to statsd" do
    assert_statsd_gauge("mfa_usage_stats.webauthn_and_totp_users", 4) do
      MfaUsageStatsJob.perform_now
    end
  end
end
