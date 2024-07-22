FactoryBot.define do
  factory :api_key do
    transient { key { "12345" } }
    transient { rubygem { nil } }

    owner factory: %i[user]
    name { "ci-key" }

    # enabled by default. disabled when show_dashboard is enabled.
    scopes { %w[index_rubygems] }

    hashed_key { Digest::SHA256.hexdigest(key) }

    after(:build) do |api_key, evaluator|
      api_key.rubygem_id = evaluator.rubygem.id if evaluator.rubygem
    end

    trait :trusted_publisher do
      owner factory: %i[oidc_trusted_publisher_github_action]
      transient { key { SecureRandom.hex(4) } }
    end
  end
end
