# frozen_string_literal: true

FactoryBot.define do
  factory :api_key_organization_scope do
    membership
    api_key { association(:api_key, key: SecureRandom.hex(24)) }
  end
end
