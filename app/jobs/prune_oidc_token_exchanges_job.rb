# frozen_string_literal: true

# Deletes the OIDC::TokenExchange rows whose tokens expired more than PRUNE_GRACE ago, and reports how many
# went and how many rows are left. A count that keeps climbing means pruning has stopped or a provider has
# started issuing long-lived tokens.
class PruneOIDCTokenExchangesJob < ApplicationJob
  queue_as :default

  def perform
    StatsD.increment("oidc.token_exchanges.pruned", OIDC::TokenExchange.prune)
    StatsD.gauge("oidc.token_exchanges.count", OIDC::TokenExchange.count)
  end
end
