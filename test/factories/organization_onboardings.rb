# frozen_string_literal: true

FactoryBot.define do
  factory :organization_onboarding do
    transient do
      approved_invites { [] }
      authorizer { create(:user) } # rubocop:disable FactoryBot/FactoryAssociationWithStrategy
    end

    created_by { association(:user) }

    sequence(:organization_name) { |n| "Organization Name #{n}" }
    sequence(:organization_handle) { |n| "organization_name_#{n}" }

    rubygems do
      [create(:rubygem, owners: [created_by])]
    end

    after(:build) do |organization_onboarding, evaluator|
      Ownership.find_or_create_by(
        user: organization_onboarding.created_by,
        rubygem: evaluator.rubygems.first,
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
  end
end
