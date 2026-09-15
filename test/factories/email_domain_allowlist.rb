# frozen_string_literal: true

FactoryBot.define do
  factory :email_domain_allowlist do
    sequence(:domain) { |n| "allowed-#{n}.example.test-domain.io" }
    notes { "exempted by ops" }
  end
end
