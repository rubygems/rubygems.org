FactoryBot.define do
  factory :org do
    handle
    name
    deleted_at { nil }

    after(:build) do |org, _evaluator|
      org.memberships << build(:membership, org: org)
    end
  end
end
