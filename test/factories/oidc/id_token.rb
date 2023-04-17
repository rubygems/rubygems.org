FactoryBot.define do
  factory :oidc_id_token, class: "OIDC::IdToken" do
    api_key_role { build(:oidc_api_key_role) }
    provider { api_key_role.provider }
    api_key { build(:api_key, user: api_key_role.user) }
    jwt do
      {
        claims: {
          claim1: "value1",
          claim2: "value2"
        },
        header: {}
      }
    end
  end
end
