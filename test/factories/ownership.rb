FactoryBot.define do
  factory :ownership do
    rubygem
    user
    confirmed_at { Time.current }
    authorizer { association :user }
    trait :unconfirmed do
      confirmed_at { nil }
    end
    access_level { Access::OWNER }

    trait :maintainer do
      access_level { Access::MAINTAINER }
    end
  end
end
