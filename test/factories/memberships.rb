FactoryBot.define do
  factory :membership do
    association :user
    association :organization
    confirmed_at { Time.zone.now }
    role { :member }

    trait :admin do
      role { :admin }
    end

    trait :owner do
      role { :owner }
    end

    trait :unconfirmed do
      confirmed_at { nil }
    end
  end
end
