# frozen_string_literal: true

FactoryBot.define do
  factory :blocked_email_domain do
    sequence(:domain) { |n| "blocked-#{n}.example.test-domain.io" }
    source { :manual }

    trait :upstream do
      source { :upstream }
    end
  end
end
