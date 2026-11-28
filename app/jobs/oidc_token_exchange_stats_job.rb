# frozen_string_literal: true

# Reports on the pruning of OIDC::TokenExchange rows from outside the job that prunes them, so a prune that
# has stopped running shows up as overdue rows instead of as metrics that have gone quiet.
class OIDCTokenExchangeStatsJob < ApplicationJob
  queue_as "stats"

  OVERDUE_AFTER = OIDC::TokenExchange::PRUNE_GRACE + 2.hours

  def perform
    StatsD.gauge("oidc.token_exchanges.count", OIDC::TokenExchange.count)
    StatsD.gauge("oidc.token_exchanges.overdue", OIDC::TokenExchange.where(expires_at: ...OVERDUE_AFTER.ago).count)
  end
end
