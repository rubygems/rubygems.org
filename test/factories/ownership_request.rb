FactoryBot.define do
  factory :ownership_request do
    rubygem
    user
    note { "small note here" }
    status { "opened" }
    approver { nil }
    trait :approved do
      approver { user }
      status { "approved" }
    end
    trait :closed do
      status { "closed" }
    end
    trait :with_ownership_call do
      ownership_call
    end
  end
end
