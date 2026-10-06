# frozen_string_literal: true

require "test_helper"

class StuckPushStatsJobTest < ActiveJob::TestCase
  include StatsD::Instrument::Assertions

  test "counts unindexed, unyanked versions past the grace period" do
    create(:version, indexed: false, created_at: 1.hour.ago) # stuck
    create(:version, indexed: false, created_at: 1.minute.ago) # push still in progress
    create(:version, indexed: false, yanked_at: 30.minutes.ago, created_at: 1.hour.ago) # yanked
    create(:version, indexed: true, created_at: 1.hour.ago)
    create(:version, indexed: false, created_at: 2.days.ago) # outside the lookback

    assert_statsd_gauge("push.stuck_versions", 1) do
      StuckPushStatsJob.perform_now
    end
  end
end
