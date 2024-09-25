FactoryBot.define do
  factory :organization_onboarding do
    transient do
      ownership { association :ownership }
    end

    title { "Rubygems" }
    slug { "rubygems" }

    invites { [1, 2, 3] }
    rubygems do
      [
        ownership.rubygem_id
      ]
    end

    created_by { ownership.user_id }

    trait :completed do
      status { :completed }
      onboarded_at { Time.zone.now }
    end
  end
end
