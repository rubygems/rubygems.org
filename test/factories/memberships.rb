FactoryBot.define do
  factory :membership do
    user
    organization
    confirmed_at { Time.zone.now }
    role { :maintainer }

    trait :maintainer do
      role { :maintainer }
    end

    trait :owner do
      role { :owner }
    end

    trait :admin do
      role { :admin }
    end
  end
end
