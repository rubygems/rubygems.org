# frozen_string_literal: true

FactoryBot.define do
  factory :oidc_trusted_publisher_id_token, class: "OIDC::TrustedPublisher::IdToken" do
    provider factory: :oidc_provider
    api_key factory: %i[api_key trusted_publisher]
    sequence(:jti) { |_n| SecureRandom.uuid }
  end
end
