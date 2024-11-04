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
  end
end
