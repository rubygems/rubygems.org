# frozen_string_literal: true

FactoryBot.define do
  factory :oidc_token_exchange, class: "OIDC::TokenExchange" do
    provider factory: :oidc_provider
    sequence(:jti) { |_n| SecureRandom.uuid }
  end
end
