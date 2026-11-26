# frozen_string_literal: true

FactoryBot.define do
  factory :temporary_push_grant do
    rubygem
    grantee { association :user, :mfa_enabled, totp_seed: ROTP::Base32.random_base32 }
    version { "1.0.0" }
    source_commit { "0123456789abcdef0123456789abcdef01234567" }
    sequence(:request_url) { "https://github.com/rubygems/temporary-push-access-log/issues/#{it}" }
    justification { "Release needed for a security fix; the owner did not respond by the deadline." }
    requester_github_login { "requester" }
    grantee_github_login { "grantee" }
    outreach_sent_at { 15.days.ago }
    response_deadline_at { 1.day.ago }
  end

  factory :temporary_push_grant_artifact do
    temporary_push_grant
    platform { "ruby" }
    sha256 { SecureRandom.hex(32) }
  end
end
