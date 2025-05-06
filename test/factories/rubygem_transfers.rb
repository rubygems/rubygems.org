FactoryBot.define do
  factory :rubygem_transfer do
    rubygem
    created_by(factory: :user)
    status { :pending }
    transferable(factory: :organization)

    created_at { Time.current }
    updated_at { Time.current }

    trait :completed do
      status { :completed }
    end

    trait :failed do
      status { :failed }
    end

    trait :pending do
      status { :pending }
    end
  end
end
