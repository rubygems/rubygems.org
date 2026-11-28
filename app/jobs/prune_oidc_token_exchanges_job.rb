# frozen_string_literal: true

# Deletes the OIDC::TokenExchange rows whose tokens expired more than PRUNE_GRACE ago, and reports how many
# went. That metric goes quiet if this job stops running, so OIDCTokenExchangeStatsJob reports what is left
# behind on its own schedule.
class PruneOIDCTokenExchangesJob < ApplicationJob
  queue_as :default

  def perform
    StatsD.increment("oidc.token_exchanges.pruned", OIDC::TokenExchange.prune)
  end
end
