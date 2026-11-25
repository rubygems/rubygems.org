# frozen_string_literal: true

FactoryBot.define do
  factory :organization_team do
    organization
    handle
    name
  end
end
