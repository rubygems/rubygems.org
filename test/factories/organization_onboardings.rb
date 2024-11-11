FactoryBot.define do
  factory :organization_onboarding do
    name_type { "user" }

    organization_name { "Rubygems" }
    organization_handle { created_by.handle }

    rubygems do
      []
    end

    created_by { association(:user) }

    trait :completed do
      status { :completed }
      onboarded_at { Time.zone.now }
    end

    trait :failed do
      error { "Failed to onboard" }
      status { :failed }
    end

    trait :gem do
      transient do
        authorizer { create(:user) } # rubocop:disable FactoryBot/FactoryAssociationWithStrategy
        rubygem { create(:rubygem) } # rubocop:disable FactoryBot/FactoryAssociationWithStrategy
      end

      name_type { "gem" }

      organization_name { rubygem.name }
      organization_handle { rubygem.name }

      rubygems do
        [rubygem.id]
      end

      after(:build) do |organization_onboarding, evaluator|
        Ownership.create(
          user: organization_onboarding.created_by,
          rubygem: evaluator.rubygem,
          authorizer: evaluator.authorizer,
          role: "owner"
        )
      end
    end
  end
end
