# frozen_string_literal: true

require "test_helper"

class OIDC::TokenExchangeTest < ActiveSupport::TestCase
  should belong_to :provider
  should validate_presence_of :expires_at

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

  test "record! stores the token's jti and when the token expires" do
    exp = 5.minutes.from_now.to_i

    exchange = OIDC::TokenExchange.record!(provider: create(:oidc_provider), jwt: { jti: "token-jti", exp: })

    assert_equal "token-jti", exchange.jti
    assert_equal Time.zone.at(exp), exchange.reload.expires_at
  end

  test "record! caps an exp later than the year 9999" do
    exchange = OIDC::TokenExchange.record!(provider: create(:oidc_provider), jwt: { jti: "token-jti", exp: 2**62 })

    assert_equal Time.zone.at(OIDC::TokenExchange::LATEST_EXP), exchange.reload.expires_at
  end

  test "prune deletes an exchange whose token expired longer ago than the grace period" do
    freeze_time
    create(:oidc_token_exchange, expires_at: OIDC::TokenExchange::PRUNE_GRACE.ago - 1.second)

    assert_equal 1, OIDC::TokenExchange.prune
    assert_empty OIDC::TokenExchange.all
  end

  test "prune keeps an exchange through the grace period after its token expires" do
    freeze_time
    exchange = create(:oidc_token_exchange, expires_at: OIDC::TokenExchange::PRUNE_GRACE.ago + 1.second)

    assert_equal 0, OIDC::TokenExchange.prune
    assert_equal exchange, OIDC::TokenExchange.sole
  end

  test "prune keeps an exchange written a minute ago, as its token is still valid" do
    exchange = create(:oidc_token_exchange, created_at: 1.minute.ago, expires_at: 4.minutes.from_now)

    assert_equal 0, OIDC::TokenExchange.prune
    assert_equal exchange, OIDC::TokenExchange.sole
  end

  test "prune goes by when the token expires, not by how old the row is" do
    provider = create(:oidc_provider)
    long_lived = create(:oidc_token_exchange, provider:, created_at: 30.days.ago, expires_at: 1.day.from_now)
    create(:oidc_token_exchange, provider:, created_at: 3.hours.ago, expires_at: 2.hours.ago)

    assert_equal 1, OIDC::TokenExchange.prune
    assert_equal long_lived, OIDC::TokenExchange.sole
  end

  test "prune keeps an exchange written before expires_at was recorded" do
    exchange = create(:oidc_token_exchange, created_at: 1.year.ago)
    exchange.update_column(:expires_at, nil)

    assert_equal 0, OIDC::TokenExchange.prune
    assert_equal exchange, OIDC::TokenExchange.sole
  end
end
