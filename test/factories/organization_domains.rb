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

    trait :deleted do
      deleted_at { Time.zone.now }
    end
  end

  factory :organization_domain_check do
    organization_domain
    checked_at { Time.zone.now }
    result { "success" }

    trait :failure do
      result { "failure" }
      error_code { "record_not_found" }
      error_message { "No TXT records found" }
    end
  end
end
