# frozen_string_literal: true

FactoryBot.define do
  factory :gem_name_reservation do
    sequence(:name) { |n| "rail-ties-#{n}" }
  end
end
