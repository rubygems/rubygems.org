class Download < DownloadsDB
  extend Timescaledb::ActsAsHypertable
  include Timescaledb::ContinuousAggregatesHelper

  acts_as_hypertable time_column: 'created_at', segment_by: [:gem_name, :gem_version]

  scope :total_downloads, -> { select("count(*) as downloads").order(:created_at) }
  scope :downloads_by_gem, -> { select("gem_name, count(*) as downloads").group(:gem_name).order(:created_at) }
  scope :downloads_by_version, -> { select("gem_name, gem_version, count(*) as downloads").group(:gem_name, :gem_version).order(:created_at) }

  continuous_aggregates(
    timeframes: [:minute, :hour, :day, :month],
    scopes: [:total_downloads, :downloads_by_gem, :downloads_by_version],
    refresh_policy: {
      minute: { start_offset: "10 minutes", end_offset: "1 minute", schedule_interval: "1 minute" },
      hour:   { start_offset: "4 hour",     end_offset: "1 hour",   schedule_interval: "1 hour" },
      day:    { start_offset: "3 day",      end_offset: "1 day",    schedule_interval: "1 day" },
      month:  { start_offset: "3 month",    end_offset: "1 day",    schedule_interval: "1 day" }
  })
end
