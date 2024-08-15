FactoryBot.define do
  factory :organization do
    transient do
      members { [] }
    end

    sequence(:handle) { |n| "organization-#{n}" }
    name { "My Organization" }

    trait :deleted do
      deleted_at { Time.zone.now }
    end

    after(:create) do |organization, evaluator|
      evaluator.members.each do |member|
        organization.users << member
      end
    end
  end
end
