FactoryBot.define do
  factory :membership do
    user
    org
    confirmed_at { Time.zone.now }
  end
end
