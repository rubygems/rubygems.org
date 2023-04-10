FactoryBot.define do
  factory :oidc_id_token, class: "OIDC::IdToken" do
    oidc_api_key_role
    jwt { "{}" }
    oidc_provider
  end
end
