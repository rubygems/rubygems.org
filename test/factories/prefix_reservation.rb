# frozen_string_literal: true

FactoryBot.define do
  factory :prefix_reservation do
    organization

    prefix { "abcs" }
  end
end
