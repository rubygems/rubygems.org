FactoryBot.define do
  factory :oidc_id_token, class: "OIDC::IdToken" do
    api_key_role factory: :oidc_api_key_role
    api_key { association :api_key, user: api_key_role.user, key: SecureRandom.hex(20) }
    jwt do
      {
        claims: {
          claim1: "value1",
          claim2: "value2",
          jti:
        },
        header: {}
      }
    end

    transient do
      sequence(:jti) { |_n| SecureRandom.uuid }
    end
  end
end
