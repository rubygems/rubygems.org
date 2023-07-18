FactoryBot.define do
  factory :user do
    email
    handle
    password { PasswordHelpers::SECURE_TEST_PASSWORD }
    api_key { "secret123" }
    email_confirmed { true }

    trait :mfa_enabled do
      totp_seed { "123abc" }
      mfa_level { User.mfa_levels["ui_and_api"] }
      mfa_recovery_codes { %w[aaa bbb ccc] } # TODO: make transient once the column is dropped
      mfa_hashed_recovery_codes { mfa_recovery_codes.map { |code| BCrypt::Password.create(code) } }
    end

    trait :disabled do
      totp_seed { "" }
      mfa_level { User.mfa_levels["disabled"] }
      mfa_recovery_codes { [] }
    end

    trait :ui_only do
      totp_seed { "123abc" }
      mfa_level { User.mfa_levels["ui_only"] }
      mfa_recovery_codes { %w[aaa bbb ccc] }
    end

    trait :ui_and_api do
      totp_seed { "123abc" }
      mfa_level { User.mfa_levels["ui_and_api"] }
      mfa_recovery_codes { %w[aaa bbb ccc] }
    end

    trait :ui_and_gem_signin do
      totp_seed { "123abc" }
      mfa_level { User.mfa_levels["ui_and_gem_signin"] }
      mfa_recovery_codes { %w[aaa bbb ccc] }
    end
  end
end
