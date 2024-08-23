# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2024_07_08_184547) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "timescaledb"

  create_table "downloads", id: false, force: :cascade do |t|
    t.timestamptz "created_at", null: false
    t.text "gem_name", null: false
    t.text "gem_version", null: false
    t.jsonb "payload"
    t.index ["created_at"], name: "downloads_created_at_idx", order: :desc
  end

  create_hypertable "downloads", time_column: "created_at", chunk_time_interval: "1 day", compress_segmentby: "gem_name, gem_version", compress_orderby: "created_at DESC", compression_interval: "P7D"
  create_continuous_aggregate("downloads_per_minute", <<-SQL, refresh_policies: { start_offset: "INTERVAL 'PT3M'", end_offset: "INTERVAL 'PT1M'", schedule_interval: "INTERVAL '60'"}, materialized_only: true, finalized: true)
    SELECT time_bucket('PT1M'::interval, created_at) AS created_at,
      count(*) AS downloads
     FROM downloads
    GROUP BY (time_bucket('PT1M'::interval, created_at))
    ORDER BY (time_bucket('PT1M'::interval, created_at))
  SQL

  create_continuous_aggregate("downloads_per_hour", <<-SQL, refresh_policies: { start_offset: "INTERVAL 'PT3H'", end_offset: "INTERVAL 'PT1M'", schedule_interval: "INTERVAL '3600'"}, materialized_only: true, finalized: true)
    SELECT time_bucket('PT1H'::interval, created_at) AS created_at,
      (sum(downloads))::bigint AS downloads
     FROM downloads_per_minute
    GROUP BY (time_bucket('PT1H'::interval, created_at))
  SQL

  create_continuous_aggregate("downloads_per_day", <<-SQL, refresh_policies: { start_offset: "INTERVAL 'P3D'", end_offset: "INTERVAL 'PT1M'", schedule_interval: "INTERVAL '86400'"}, materialized_only: true, finalized: true)
    SELECT time_bucket('P1D'::interval, created_at) AS created_at,
      (sum(downloads))::bigint AS downloads
     FROM downloads_per_hour
    GROUP BY (time_bucket('P1D'::interval, created_at))
  SQL

  create_continuous_aggregate("downloads_per_month", <<-SQL, refresh_policies: { start_offset: "INTERVAL 'P3M'", end_offset: "INTERVAL 'PT1M'", schedule_interval: "INTERVAL '2629746'"}, materialized_only: true, finalized: true)
    SELECT time_bucket('P1M'::interval, created_at) AS created_at,
      (sum(downloads))::bigint AS downloads
     FROM downloads_per_day
    GROUP BY (time_bucket('P1M'::interval, created_at))
  SQL

  create_continuous_aggregate("downloads_gems_per_minute", <<-SQL, refresh_policies: { start_offset: "INTERVAL 'PT3M'", end_offset: "INTERVAL 'PT1M'", schedule_interval: "INTERVAL '60'"}, materialized_only: true, finalized: true)
    SELECT time_bucket('PT1M'::interval, created_at) AS created_at,
      gem_name,
      count(*) AS downloads
     FROM downloads
    GROUP BY (time_bucket('PT1M'::interval, created_at)), gem_name
    ORDER BY (time_bucket('PT1M'::interval, created_at))
  SQL

  create_continuous_aggregate("downloads_gems_per_hour", <<-SQL, refresh_policies: { start_offset: "INTERVAL 'PT3H'", end_offset: "INTERVAL 'PT1M'", schedule_interval: "INTERVAL '3600'"}, materialized_only: true, finalized: true)
    SELECT time_bucket('PT1H'::interval, created_at) AS created_at,
      gem_name,
      (sum(downloads))::bigint AS downloads
     FROM downloads_gems_per_minute
    GROUP BY (time_bucket('PT1H'::interval, created_at)), gem_name
  SQL

  create_continuous_aggregate("downloads_gems_per_day", <<-SQL, refresh_policies: { start_offset: "INTERVAL 'P3D'", end_offset: "INTERVAL 'PT1M'", schedule_interval: "INTERVAL '86400'"}, materialized_only: true, finalized: true)
    SELECT time_bucket('P1D'::interval, created_at) AS created_at,
      gem_name,
      (sum(downloads))::bigint AS downloads
     FROM downloads_gems_per_hour
    GROUP BY (time_bucket('P1D'::interval, created_at)), gem_name
  SQL

  create_continuous_aggregate("downloads_gems_per_month", <<-SQL, refresh_policies: { start_offset: "INTERVAL 'P3M'", end_offset: "INTERVAL 'PT1M'", schedule_interval: "INTERVAL '2629746'"}, materialized_only: true, finalized: true)
    SELECT time_bucket('P1M'::interval, created_at) AS created_at,
      gem_name,
      (sum(downloads))::bigint AS downloads
     FROM downloads_gems_per_day
    GROUP BY (time_bucket('P1M'::interval, created_at)), gem_name
  SQL

  create_continuous_aggregate("downloads_versions_per_minute", <<-SQL, refresh_policies: { start_offset: "INTERVAL 'PT3M'", end_offset: "INTERVAL 'PT1M'", schedule_interval: "INTERVAL '60'"}, materialized_only: true, finalized: true)
    SELECT time_bucket('PT1M'::interval, created_at) AS created_at,
      gem_name,
      gem_version,
      count(*) AS downloads
     FROM downloads
    GROUP BY (time_bucket('PT1M'::interval, created_at)), gem_name, gem_version
    ORDER BY (time_bucket('PT1M'::interval, created_at))
  SQL

  create_continuous_aggregate("downloads_versions_per_hour", <<-SQL, refresh_policies: { start_offset: "INTERVAL 'PT3H'", end_offset: "INTERVAL 'PT1M'", schedule_interval: "INTERVAL '3600'"}, materialized_only: true, finalized: true)
    SELECT time_bucket('PT1H'::interval, created_at) AS created_at,
      gem_name,
      gem_version,
      (sum(downloads))::bigint AS downloads
     FROM downloads_versions_per_minute
    GROUP BY (time_bucket('PT1H'::interval, created_at)), gem_name, gem_version
  SQL

  create_continuous_aggregate("downloads_versions_per_day", <<-SQL, refresh_policies: { start_offset: "INTERVAL 'P3D'", end_offset: "INTERVAL 'PT1M'", schedule_interval: "INTERVAL '86400'"}, materialized_only: true, finalized: true)
    SELECT time_bucket('P1D'::interval, created_at) AS created_at,
      gem_name,
      gem_version,
      (sum(downloads))::bigint AS downloads
     FROM downloads_versions_per_hour
    GROUP BY (time_bucket('P1D'::interval, created_at)), gem_name, gem_version
  SQL

  create_continuous_aggregate("downloads_versions_per_month", <<-SQL, refresh_policies: { start_offset: "INTERVAL 'P3M'", end_offset: "INTERVAL 'PT1M'", schedule_interval: "INTERVAL '2629746'"}, materialized_only: true, finalized: true)
    SELECT time_bucket('P1M'::interval, created_at) AS created_at,
      gem_name,
      gem_version,
      (sum(downloads))::bigint AS downloads
     FROM downloads_versions_per_day
    GROUP BY (time_bucket('P1M'::interval, created_at)), gem_name, gem_version
  SQL

end
