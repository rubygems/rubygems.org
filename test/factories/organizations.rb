FactoryBot.define do
  factory :organization do
    transient do
      owners { [] }
      admins { [] }
      maintainers { [] }
      rubygems { [] }
    end

    handle
    name
    deleted_at { nil }

    after(:create) do |organization, evaluator|
      evaluator.owners.each do |user|
        create(:membership, user: user, organization: organization, role: :owner, confirmed_at: Time.zone.now)
      end

      evaluator.admins.each do |user|
        create(:membership, user: user, organization: organization, role: :admin, confirmed_at: Time.zone.now)
      end

      evaluator.maintainers.each do |user|
        create(:membership, user: user, organization: organization, role: :maintainer, confirmed_at: Time.zone.now)
      end

      evaluator.rubygems.each do |rubygem|
        rubygem.update(organization: organization)
      end
    end

    trait :with_members do
      memberships { build_list(:membership, 2) }
    end
  end
end
