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

ActiveRecord::Schema[7.0].define(version: 2023_03_08_224729) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "timescaledb"
  enable_extension "timescaledb_toolkit"

  create_table "downloads", id: false, force: :cascade do |t|
    t.integer "rubygem_id", null: false
    t.integer "version_id", null: false
    t.integer "downloads", null: false
    t.integer "log_ticket_id"
    t.timestamptz "occurred_at", null: false
    t.index ["occurred_at"], name: "downloads_occurred_at_idx", order: :desc
    t.index ["rubygem_id", "version_id", "occurred_at", "log_ticket_id"], name: "idx_downloads_by_version_log_ticket", unique: true
  end

  create_hypertable "downloads", "occurred_at", chunk_time_interval: "7 days"

  create_continuous_aggregate "downloads_15_minutes", <<-SQL
    SELECT time_bucket('PT15M'::interval, downloads.occurred_at) AS occurred_at,
      downloads.rubygem_id,
      downloads.version_id,
      sum(downloads.downloads) AS downloads
     FROM downloads
    GROUP BY (time_bucket('PT15M'::interval, downloads.occurred_at)), downloads.rubygem_id, downloads.version_id;
  SQL

  add_continuous_aggregate_policy "downloads_15_minutes", "1 week", "1 hour", "1 hour"

  create_continuous_aggregate "downloads_1_day", <<-SQL
    SELECT time_bucket('P1D'::interval, downloads_15_minutes.occurred_at) AS occurred_at,
      downloads_15_minutes.rubygem_id,
      downloads_15_minutes.version_id,
      sum(downloads_15_minutes.downloads) AS downloads
     FROM downloads_15_minutes
    GROUP BY (time_bucket('P1D'::interval, downloads_15_minutes.occurred_at)), downloads_15_minutes.rubygem_id, downloads_15_minutes.version_id;
  SQL

  add_continuous_aggregate_policy "downloads_1_day", "2 years", "1 day", "12 hours"

  create_continuous_aggregate "downloads_1_month", <<-SQL
    SELECT time_bucket('P1M'::interval, downloads_1_day.occurred_at) AS occurred_at,
      downloads_1_day.rubygem_id,
      downloads_1_day.version_id,
      sum(downloads_1_day.downloads) AS downloads
     FROM downloads_1_day
    GROUP BY (time_bucket('P1M'::interval, downloads_1_day.occurred_at)), downloads_1_day.rubygem_id, downloads_1_day.version_id;
  SQL

  add_continuous_aggregate_policy "downloads_1_month", nil, "1 month", "1 day"

  create_continuous_aggregate "downloads_1_year", <<-SQL
    SELECT time_bucket('P1Y'::interval, downloads_1_month.occurred_at) AS occurred_at,
      downloads_1_month.rubygem_id,
      downloads_1_month.version_id,
      sum(downloads_1_month.downloads) AS downloads
     FROM downloads_1_month
    GROUP BY (time_bucket('P1Y'::interval, downloads_1_month.occurred_at)), downloads_1_month.rubygem_id, downloads_1_month.version_id;
  SQL

  add_continuous_aggregate_policy "downloads_1_year", nil, "1 year", "1 month"

  create_continuous_aggregate "downloads_1_year_all_versions", <<-SQL
    SELECT time_bucket('P1Y'::interval, downloads_1_year.occurred_at) AS occurred_at,
      downloads_1_year.rubygem_id,
      sum(downloads_1_year.downloads) AS downloads
     FROM downloads_1_year
    GROUP BY (time_bucket('P1Y'::interval, downloads_1_year.occurred_at)), downloads_1_year.rubygem_id
    ORDER BY (time_bucket('P1Y'::interval, downloads_1_year.occurred_at));
  SQL

  add_continuous_aggregate_policy "downloads_1_year_all_versions", nil, "1 year", "1 month"

  create_continuous_aggregate "downloads_1_year_all_gems", <<-SQL
    SELECT time_bucket('P1Y'::interval, downloads_1_year_all_versions.occurred_at) AS occurred_at,
      sum(downloads_1_year_all_versions.downloads) AS downloads
     FROM downloads_1_year_all_versions
    GROUP BY (time_bucket('P1Y'::interval, downloads_1_year_all_versions.occurred_at))
    ORDER BY (time_bucket('P1Y'::interval, downloads_1_year_all_versions.occurred_at));
  SQL

  add_continuous_aggregate_policy "downloads_1_year_all_gems", nil, "1 year", "1 month"

  create_continuous_aggregate "downloads_15_minutes_all_versions", <<-SQL
    SELECT time_bucket('PT15M'::interval, downloads_15_minutes.occurred_at) AS occurred_at,
      downloads_15_minutes.rubygem_id,
      sum(downloads_15_minutes.downloads) AS downloads
     FROM downloads_15_minutes
    GROUP BY (time_bucket('PT15M'::interval, downloads_15_minutes.occurred_at)), downloads_15_minutes.rubygem_id
    ORDER BY (time_bucket('PT15M'::interval, downloads_15_minutes.occurred_at));
  SQL

  add_continuous_aggregate_policy "downloads_15_minutes_all_versions", "1 week", "1 hour", "1 hour"

  create_continuous_aggregate "downloads_15_minutes_all_gems", <<-SQL
    SELECT time_bucket('PT15M'::interval, downloads_15_minutes_all_versions.occurred_at) AS occurred_at,
      sum(downloads_15_minutes_all_versions.downloads) AS downloads
     FROM downloads_15_minutes_all_versions
    GROUP BY (time_bucket('PT15M'::interval, downloads_15_minutes_all_versions.occurred_at))
    ORDER BY (time_bucket('PT15M'::interval, downloads_15_minutes_all_versions.occurred_at));
  SQL

  add_continuous_aggregate_policy "downloads_15_minutes_all_gems", "1 week", "1 hour", "1 hour"

  create_continuous_aggregate "downloads_1_day_all_versions", <<-SQL
    SELECT time_bucket('P1D'::interval, downloads_1_day.occurred_at) AS occurred_at,
      downloads_1_day.rubygem_id,
      sum(downloads_1_day.downloads) AS downloads
     FROM downloads_1_day
    GROUP BY (time_bucket('P1D'::interval, downloads_1_day.occurred_at)), downloads_1_day.rubygem_id
    ORDER BY (time_bucket('P1D'::interval, downloads_1_day.occurred_at));
  SQL

  add_continuous_aggregate_policy "downloads_1_day_all_versions", "2 years", "1 day", "12 hours"

  create_continuous_aggregate "downloads_1_day_all_gems", <<-SQL
    SELECT time_bucket('P1D'::interval, downloads_1_day_all_versions.occurred_at) AS occurred_at,
      sum(downloads_1_day_all_versions.downloads) AS downloads
     FROM downloads_1_day_all_versions
    GROUP BY (time_bucket('P1D'::interval, downloads_1_day_all_versions.occurred_at))
    ORDER BY (time_bucket('P1D'::interval, downloads_1_day_all_versions.occurred_at));
  SQL

  add_continuous_aggregate_policy "downloads_1_day_all_gems", "2 years", "1 day", "12 hours"

  create_continuous_aggregate "downloads_1_month_all_versions", <<-SQL
    SELECT time_bucket('P1M'::interval, downloads_1_month.occurred_at) AS occurred_at,
      downloads_1_month.rubygem_id,
      sum(downloads_1_month.downloads) AS downloads
     FROM downloads_1_month
    GROUP BY (time_bucket('P1M'::interval, downloads_1_month.occurred_at)), downloads_1_month.rubygem_id
    ORDER BY (time_bucket('P1M'::interval, downloads_1_month.occurred_at));
  SQL

  add_continuous_aggregate_policy "downloads_1_month_all_versions", nil, "1 month", "1 day"

  create_continuous_aggregate "downloads_1_month_all_gems", <<-SQL
    SELECT time_bucket('P1M'::interval, downloads_1_month_all_versions.occurred_at) AS occurred_at,
      sum(downloads_1_month_all_versions.downloads) AS downloads
     FROM downloads_1_month_all_versions
    GROUP BY (time_bucket('P1M'::interval, downloads_1_month_all_versions.occurred_at))
    ORDER BY (time_bucket('P1M'::interval, downloads_1_month_all_versions.occurred_at));
  SQL

  add_continuous_aggregate_policy "downloads_1_month_all_gems", nil, "1 month", "1 day"

end
