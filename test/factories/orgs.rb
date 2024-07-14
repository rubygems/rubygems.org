FactoryBot.define do
  factory :org do
    handle
    name
    deleted_at { nil }

    trait :with_members do
      memberships { build_list(:membership, 2) }
    end
  end
end
