# frozen_string_literal: true

FactoryBot.define do
  factory :advisory, class: "Advisory::OSV" do
    sequence(:identifier) { |n| format("GHSA-%04x-%04x-%04x", n, n, n) }
    rubygem_name { "example" }
    summary { "Example advisory summary" }
    url { "https://osv.dev/vulnerability/#{identifier}" }
    severity { :moderate }
    modified_at { Time.current }
    aliases { [] }
    ranges { [] }
    payload { {} }

    trait :withdrawn do
      withdrawn_at { Time.current }
    end

    trait :with_rubygem do
      rubygem
      rubygem_name { rubygem.name }
    end

    trait :unfixed do
      ranges { ["introduced" => "0"] }
    end

    trait :range do
      ranges { ["introduced" => "1.0.0", "fixed" => "1.2.0"] }
    end

    trait :exact do
      ranges { ["introduced" => "1.0.0", "last_affected" => "1.0.0"] }
    end
  end
end
