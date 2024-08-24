class CreateDownloads < ActiveRecord::Migration[7.1]

  disable_ddl_transaction!

  def self.up
    self.down if Download.table_exists?

    hypertable_options = {
      time_column: 'created_at',
      chunk_time_interval: '1 day',
      compress_segmentby: 'gem_name, gem_version',
      compress_orderby: 'created_at DESC',
      compression_interval: '7 days'
    }

    create_table(:downloads, id: false, hypertable: hypertable_options) do |t|
      t.timestamptz :created_at, null: false
      t.text :gem_name, :gem_version, null: false
      t.jsonb :payload
    end

    {
      per_minute: Download.per_minute,
      per_hour: Download::PerMinute.per_hour(:sum_downloads).group(1),
      per_day: Download::PerHour.per_day(:sum_downloads).group(1),
      per_month: Download::PerDay.per_month(:sum_downloads).group(1),

      gems_per_minute: Download.gems_per_minute,
      gems_per_hour: Download::GemsPerMinute.per_hour("gem_name, sum(downloads)::bigint as downloads").group(1,2),
      gems_per_day: Download::GemsPerHour.per_day("gem_name, sum(downloads)::bigint as downloads").group(1,2),
      gems_per_month: Download::GemsPerDay.per_month("gem_name, sum(downloads)::bigint as downloads").group(1,2),

      versions_per_minute: Download.versions_per_minute,
      versions_per_hour: Download::VersionsPerMinute.sum_downloads.per_hour("gem_name, gem_version").group(1,2,3),
      versions_per_day: Download::VersionsPerHour.sum_downloads.per_day("gem_name, gem_version").group(1,2,3),
      versions_per_month: Download::VersionsPerDay.sum_downloads.per_month("gem_name, gem_version").group(1,2,3)
    }.each do |name, scope|
      frame = name.to_s.split('per_').last
      create_continuous_aggregate(
        "downloads_#{name}",
        scope.to_sql,
        refresh_policies: {
          schedule_interval: "INTERVAL '1 #{frame}'",
          start_offset: "INTERVAL '3 #{frame}'",
          end_offset: "INTERVAL '1 minute'"
        })
    end
  end
  def self.down
    %w[month day hour minute].each do |frame|
      ["downloads_per_#{frame}",
       "downloads_gems_per_#{frame}",
       "downloads_versions_per_#{frame}",
      ].each do |view|
        safety_assured do
          execute("DROP MATERIALIZED VIEW IF EXISTS #{view} cascade")
        end
      end
    end

    drop_table(:downloads, force: :cascade, if_exists: true) if Download.table_exists?
  end
end
