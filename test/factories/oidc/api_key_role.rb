FactoryBot.define do
  factory :oidc_api_key_role, class: "OIDC::ApiKeyRole" do
    provider { build(:oidc_provider) }
    user
    api_key_permissions do
      {
        scopes: ["push_rubygem"]
      }
    end
    name { "GitHub Pusher" }
    access_policy do
      {
        statements: [
          { effect: "allow",
            principal: { oidc: provider.issuer },
            conditions: [] }
        ]
      }
    end
  end
end
