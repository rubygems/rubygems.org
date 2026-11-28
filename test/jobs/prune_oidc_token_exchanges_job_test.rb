# frozen_string_literal: true

require "test_helper"

class PruneOIDCTokenExchangesJobTest < ActiveJob::TestCase
  include StatsD::Instrument::Assertions

  setup do
    provider = create(:oidc_provider)
    create(:oidc_token_exchange, provider:, expires_at: 2.hours.ago)
    @unexpired = create(:oidc_token_exchange, provider:, expires_at: 4.minutes.from_now)
  end

  test "deletes the exchanges of tokens that expired longer ago than the grace period" do
    PruneOIDCTokenExchangesJob.perform_now

    assert_equal @unexpired, OIDC::TokenExchange.sole
  end

  test "reports how many rows it deleted" do
    assert_statsd_increment("oidc.token_exchanges.pruned", 1) do
      PruneOIDCTokenExchangesJob.perform_now
    end
  end

  test "is scheduled, as nothing else deletes these rows" do
    schedule = Rails.application.config.good_job.cron.fetch(:prune_oidc_token_exchanges)

    assert_equal PruneOIDCTokenExchangesJob.name, schedule.fetch(:class)
  end
end
