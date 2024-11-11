FactoryBot.define do
  factory :organization_onboarding do
    transient do
      approved_invites { [] }
      authorizer { association(:user) }
      namesake_rubygem { create(:rubygem) } # rubocop:disable FactoryBot/FactoryAssociationWithStrategy
    end

    created_by { association(:user) }

    name_type { "gem" }

    organization_name { namesake_rubygem.name }
    organization_handle { namesake_rubygem.name }

    rubygems do
      [namesake_rubygem.id]
    end

    after(:build) do |organization_onboarding, evaluator|
      Ownership.find_or_create_by(
        user: organization_onboarding.created_by,
        rubygem: evaluator.namesake_rubygem,
        authorizer: evaluator.authorizer,
        role: "owner"
      )
      evaluator.approved_invites.each do |invitee|
        organization_onboarding.invites.find_or_initialize_by(user: invitee[:user]).role = invitee[:role]
      end
    end

    trait :completed do
      status { :completed }
      onboarded_at { Time.zone.now }
    end

    trait :failed do
      error { "Failed to onboard" }
      status { :failed }
    end

    trait :username do
      name_type { "user" }

      organization_name { "Rubygems" }
      organization_handle { created_by.handle }

      rubygems do
        []
      end

      after(:build) do |organization_onboarding, evaluator|
        Ownership.find_or_create_by(
          user: organization_onboarding.created_by,
          rubygem: evaluator.namesake_rubygem,
          authorizer: evaluator.authorizer,
          role: "owner"
        )
      end
    end
  end
end
