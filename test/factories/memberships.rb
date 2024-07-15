FactoryBot.define do
  factory :membership do
    user
    organization
    confirmed_at { Time.zone.now }
  end
end
