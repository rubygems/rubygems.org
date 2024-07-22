FactoryBot.define do
  factory :ownership do
    rubygem
    user
    confirmed_at { Time.current }
    authorizer { association :user }
    trait :unconfirmed do
      confirmed_at { nil }
    end
  end
end
