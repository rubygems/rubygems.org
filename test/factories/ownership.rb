FactoryBot.define do
  factory :ownership do
    rubygem
    user
    confirmed_at { Time.current }
    authorizer { association :user }
    role { :owner }

    trait :unconfirmed do
      confirmed_at { nil }
    end

    trait :maintainer do
      role { :maintainer }
    end
  end
end
