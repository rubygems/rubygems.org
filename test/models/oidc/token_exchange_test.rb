# frozen_string_literal: true

require "test_helper"

class OIDC::TokenExchangeTest < ActiveSupport::TestCase
  should belong_to :provider

  test "enforces single use of a jti per provider at the database level" do
    exchange = create(:oidc_token_exchange)

    assert_raises(ActiveRecord::RecordNotUnique) do
      create(:oidc_token_exchange, provider: exchange.provider, jti: exchange.jti)
    end
  end

  test "allows the same jti from another provider" do
    exchange = create(:oidc_token_exchange)
    other = create(:oidc_token_exchange, jti: exchange.jti)

    refute_equal exchange.provider, other.provider
    assert_predicate other, :persisted?
  end
end
