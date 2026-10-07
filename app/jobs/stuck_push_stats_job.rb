# frozen_string_literal: true

# A push that fails after its version row is saved leaves the version unindexed
# without a deletion, and retries are rejected with "did not finish pushing".
class StuckPushStatsJob < ApplicationJob
  queue_as "stats"

  LOOKBACK = 1.day

  def perform
    stuck = Version.where(indexed: false, yanked_at: nil)
      .where(created_at: LOOKBACK.ago..Version::PUSH_GRACE_PERIOD.ago)
      .count

    StatsD.gauge("push.stuck_versions", stuck)
  end
end
