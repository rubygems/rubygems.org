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
          { effect: "allow",
            principal: { oidc: provider.issuer },
            conditions: [
              { operator: "string_equals", claim: "sub", value: "repo:segiddins/oidc-test:ref:refs/heads/main" }
            ] }
        ]
      }
    end
  end
end
