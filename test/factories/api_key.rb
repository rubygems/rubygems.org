FactoryBot.define do
  factory :api_key do
    transient { key { "12345" } }

    owner factory: %i[user]
    name { "ci-key" }

    # enabled by default. disabled when show_dashboard is enabled.
    scopes { %w[index_rubygems] }

    hashed_key { Digest::SHA256.hexdigest(key) }
  end
end
