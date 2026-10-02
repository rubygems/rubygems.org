# frozen_string_literal: true

FactoryBot.define do
  factory :historical_ownership do
    rubygem
    user
    first_owned_at { Time.current }
    removed_at { nil }

    trait :removed do
      removed_at { Time.current }
    end
  end
end
