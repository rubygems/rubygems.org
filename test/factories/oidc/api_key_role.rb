FactoryBot.define do
  factory :oidc_api_key_role, class: "OIDC::ApiKeyRole" do
    provider factory: :oidc_provider
    user
    api_key_permissions do
      {
        scopes: ["push_rubygem"]
      }
    end
    sequence(:name) { |n| "GitHub Pusher #{n}" }
    access_policy do
      {
        statements: [
          effect: "allow",
           principal: { oidc: provider.issuer },
           conditions: [
             operator: "string_equals", claim: "sub", value: "repo:segiddins/oidc-test:ref:refs/heads/main"
           ]
        ]
      }
    end

    trait :buildkite do
      provider factory: :oidc_provider_buildkite
      sequence(:name) { |n| "Buildkite Pusher #{n}" }
      access_policy do
        {
          statements: [
            effect: "allow",
             principal: { oidc: provider.issuer },
             conditions: [
               operator: "string_equals", claim: "organization_slug", value: "example-org"
             ]
          ]
        }
      end
    end

    factory :oidc_api_key_role_buildkite, traits: [:buildkite]
  end
end
