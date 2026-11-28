# frozen_string_literal: true

require "test_helper"

class OIDCTokenExchangeStatsJobTest < ActiveJob::TestCase
  include StatsD::Instrument::Assertions

  setup do
    freeze_time
    @provider = create(:oidc_provider)
  end

  test "reports how many rows there are" do
    create(:oidc_token_exchange, provider: @provider)
    create(:oidc_token_exchange, provider: @provider, expires_at: 1.day.ago)

    assert_statsd_gauge("oidc.token_exchanges.count", 2) do
      OIDCTokenExchangeStatsJob.perform_now
    end
  end

  test "reports no overdue rows while pruning keeps up" do
    create(:oidc_token_exchange, provider: @provider)
    create(:oidc_token_exchange, provider: @provider, expires_at: OIDCTokenExchangeStatsJob::OVERDUE_AFTER.ago + 1.second)

    assert_statsd_gauge("oidc.token_exchanges.overdue", 0) do
      OIDCTokenExchangeStatsJob.perform_now
    end
  end

  test "reports the rows pruning has missed, until it deletes them" do
    create(:oidc_token_exchange, provider: @provider, expires_at: OIDCTokenExchangeStatsJob::OVERDUE_AFTER.ago - 1.second)

    assert_statsd_gauge("oidc.token_exchanges.overdue", 1) do
      OIDCTokenExchangeStatsJob.perform_now
    end

    OIDC::TokenExchange.prune

    assert_statsd_gauge("oidc.token_exchanges.overdue", 0) do
      OIDCTokenExchangeStatsJob.perform_now
    end
  end

  test "does not count a row written before expires_at was recorded as overdue" do
    create(:oidc_token_exchange, provider: @provider, created_at: 1.year.ago).update_column(:expires_at, nil)

    assert_statsd_gauge("oidc.token_exchanges.overdue", 0) do
      OIDCTokenExchangeStatsJob.perform_now
    end
  end

  test "is scheduled, as the prune job cannot report that it has stopped" do
    cron = Rails.application.config.good_job.cron

    assert_equal OIDCTokenExchangeStatsJob.name, cron.fetch(:oidc_token_exchange_stats).fetch(:class)
  end
end
