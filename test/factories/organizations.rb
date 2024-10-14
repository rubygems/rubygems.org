FactoryBot.define do
  factory :organization do
    transient do
      owners { [] }
      admins { [] }
      maintainers { [] }
    end

    handle
    name
    deleted_at { nil }

    after(:create) do |organization, evaluator|
      evaluator.owners.each do |user|
        create(:membership, user: user, organization: organization, role: :owner)
      end

      evaluator.admins.each do |user|
        create(:membership, user: user, organization: organization, role: :admin)
      end

      evaluator.maintainers.each do |user|
        create(:membership, user: user, organization: organization, role: :maintainer)
      end
    end

    trait :with_members do
      memberships { build_list(:membership, 2) }
    end
  end
end
