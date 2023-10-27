FactoryBot.define do
  factory :link_verification do
    linkable factory: :rubygem
    sequence(:uri) { |n| "https://example.com/#{n}" }
    last_verified_at { nil }
    last_failure_at { nil }
    failures_since_last_verification { 0 }
  end
end
