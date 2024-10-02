FactoryBot.define do
  factory :organization_onboarding do
    transient do
      ownership { association :ownership }
    end

    title { "Rubygems" }
    slug { "rubygems" }

    invitees do
      {
        ownership.user_id => "owner"
      }
    end

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
