FactoryBot.define do
  factory :org do
    handle { |i| "org_#{i}" }
    name { |i| "Organization #{i}" }
    deleted_at { nil }
  end
end
