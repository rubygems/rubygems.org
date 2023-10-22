FactoryBot.define do
  factory :oidc_id_token, class: "OIDC::IdToken" do
    api_key_role factory: :oidc_api_key_role
    api_key { association :api_key, key: SecureRandom.hex(20), **api_key_role.api_key_permissions.create_params(api_key_role.user) }
    jwt do
      {
        claims: {
          claim1: "value1",
          claim2: "value2",
          jti:
        },
        header: {
          alg: "RS256",
          kid: "test",
          typ: "JWT"
        }
      }
    end

    transient do
      sequence(:jti) { |_n| SecureRandom.uuid }
    end
  end
end
