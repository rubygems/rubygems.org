# frozen_string_literal: true

module HistoricalOwnershipsHelper
  def historical_ownerships_enabled?(viewer = nil)
    FeatureFlag.enabled?(FeatureFlag::HISTORICAL_OWNERSHIPS, viewer)
  end
end
