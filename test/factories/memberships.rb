FactoryBot.define do
  factory :membership do
    user
    org
    confirmed_at { Time.now }
  end
end
