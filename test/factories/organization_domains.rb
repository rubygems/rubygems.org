# frozen_string_literal: true

FactoryBot.define do
  factory :organization_domain do
    organization
    sequence(:domain) { |n| "domain-#{n}.example.com" }

    trait :verified do
      verified_at { Time.zone.now }
      last_checked_at { verified_at }
      last_check_result { "success" }
    end
  end

  factory :organization_domain_check do
    organization_domain
    checked_at { Time.zone.now }
    result { "success" }
    outcome { "matched" }

    trait :failure do
      result { "failure" }
      outcome { "record_not_found" }
      message { "No TXT record found at _rubygems-challenge.example.com." }
    end
  end
end
