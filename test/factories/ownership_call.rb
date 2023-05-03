FactoryBot.define do
  factory :ownership_call do
    rubygem
    user
    note { "small note" }
    trait :closed do
      status { "closed" }
    end
  end
end
