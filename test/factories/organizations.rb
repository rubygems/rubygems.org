FactoryBot.define do
  factory :organization do
    handle
    name
    deleted_at { nil }

    trait :with_members do
      memberships { build_list(:membership, 2) }
    end
  end
end
