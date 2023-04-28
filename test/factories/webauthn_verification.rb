FactoryBot.define do
  factory :webauthn_verification do
    user
    path_token { SecureRandom.base58(16) }
    path_token_expires_at { Time.now.utc + 2.minutes }
    otp { SecureRandom.base58(16) }
    otp_expires_at { Time.now.utc + 2.minutes }
  end
end
