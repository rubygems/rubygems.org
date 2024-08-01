FactoryBot.define do
  factory :ownership do
    rubygem
    user
    confirmed_at { Time.current }
    authorizer { association :user }
    access_level { Access::OWNER }

    trait :unconfirmed do
      confirmed_at { nil }
    end

    trait :maintainer do
      access_level { Access::MAINTAINER }
    end
  end
end
