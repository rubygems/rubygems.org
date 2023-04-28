FactoryBot.define do
  factory :webauthn_credential do
    user
    sequence(:external_id) { |n| "webauthn-credential-#{n}" }
    public_key { "abc" }
    nickname { "Key #{SecureRandom.hex(24)}" }

    trait :primary

    trait :backup do
      nickname { "Backup key" }
    end
  end
end
