class CreateDownloadsContinuousAggregates < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def quote_table_name(...)
    connection.quote_table_name(...)
  end

  def continuous_aggregate(
    duration:,
    from: Download.table_name,
    start_offset:,
    end_offset:,
    schedule_window:,
    retention: start_offset
  )
    name = "downloads_" + duration.inspect.parameterize(separator: '_')

    create_continuous_aggregate(
      name,
      Download.
        time_bucket(duration.iso8601, quote_table_name("#{from}.occurred_at"), select_alias: 'occurred_at').
        group(:rubygem_id, :version_id).
        select(:rubygem_id, :version_id).
        sum(quote_table_name("#{from}.downloads"), :downloads).
        reorder(nil).
        from(from).
        to_sql,
      force: true
    )
    add_continuous_aggregate_policy(name, start_offset&.iso8601, end_offset&.iso8601, schedule_window)
    add_hypertable_retention_policy(name, retention.iso8601) if retention

    all_versions_name = name + "_all_versions"
    create_continuous_aggregate(
      all_versions_name,
      Download.
        time_bucket(duration.iso8601, quote_table_name("#{name}.occurred_at"), select_alias: 'occurred_at').
        group(:rubygem_id).
        select(:rubygem_id).
        sum(quote_table_name("#{name}.downloads"), :downloads).
        from(name).
        to_sql,
        force: true
    )
    add_continuous_aggregate_policy(all_versions_name, start_offset&.iso8601, end_offset&.iso8601, schedule_window)
    add_hypertable_retention_policy(all_versions_name, retention.iso8601) if retention

    all_gems_name = name + "_all_gems"
    create_continuous_aggregate(
      all_gems_name,
      Download.
        time_bucket(duration.iso8601, quote_table_name("#{all_versions_name}.occurred_at"), select_alias: 'occurred_at').
        sum(quote_table_name("#{all_versions_name}.downloads"), :downloads).
        from(all_versions_name).
        to_sql,
        force: true
    )
    add_continuous_aggregate_policy(all_gems_name, start_offset&.iso8601, end_offset&.iso8601, schedule_window)
    add_hypertable_retention_policy(all_gems_name, retention.iso8601) if retention

    name
  end

  def change
    # https://github.com/timescale/timescaledb/issues/5474
    Download.create!(version_id: 0, rubygem_id: 0, occurred_at: Time.at(0), downloads: 0)

    from = continuous_aggregate(
      duration: 15.minutes,
      start_offset: 1.week,
      end_offset: 1.hour,
      schedule_window: 1.hour
    )

    from = continuous_aggregate(
      duration: 1.day,
      start_offset: 2.years,
      end_offset: 1.day,
      schedule_window: 12.hours,
      from:
    )

    from = continuous_aggregate(
      duration: 1.month,
      start_offset: nil,
      end_offset: 1.month,
      schedule_window: 1.day,
      retention: nil,
      from:
    )

    from = continuous_aggregate(
      duration: 1.year,
      start_offset: nil,
      end_offset: 1.year,
      schedule_window: 1.month,
      retention: nil,
      from:
    )
  end
end
