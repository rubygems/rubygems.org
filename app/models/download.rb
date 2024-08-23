class Download < DownloadRecord
  extend Timescaledb::ActsAsHypertable

  acts_as_hypertable time_column: 'created_at'

  scope :time_bucket, -> (range='1m', query="count(*)") do
    time_column = self.hypertable_options[:time_column]
    select("time_bucket('#{range}', #{time_column}) as #{time_column}, #{query}")
  end

  scope :per_minute, -> (query="count(*) as downloads") do
    time_bucket('1m', query).group(1).order(1)
  end

  scope :gems_per_minute, -> do
    per_minute("gem_name, count(*) as downloads").group(1,2)
  end

  scope :versions_per_minute, -> do
    per_minute("gem_name, gem_version, count(*) as downloads").group(1,2,3)
  end

  cagg = -> (view_name) do
    Class.new(DownloadRecord) do
      self.table_name = "downloads_#{view_name}"

      scope :sum_downloads, -> { select("sum(downloads)::bigint as downloads") }
      scope :avg_downloads, -> { select("avg(downloads)::bigint as avg_downloads") }

      scope :rollup, -> (range='1d', query=:sum_downloads) do
        time_column = Download.hypertable_options[:time_column]
        if query.is_a?(Symbol)
          select("time_bucket('#{range}', #{time_column}) as #{time_column}")
          .public_send(query)
          .group(1)
        else
          select("time_bucket('#{range}', #{time_column}) as #{time_column}, #{query}")
          .group(1)
        end
      end

      scope :per_hour, -> (query=:sum_downloads) do
        rollup('1h', query)
      end

      scope :per_day, -> (query=:sum_downloads) do
        rollup('1d', query)
      end

      scope :per_week, -> (query=:sum_downloads) do
        rollup('1w', query)
      end

      scope :per_month, -> (query=:sum_downloads) do
        rollup('1mon', query)
      end

      scope :per_year, -> (query=:sum_downloads) do
        rollup('1y', query)
      end

      def readonly?
        true
      end

      def self.refresh!
        connection_pool.with_connection do |conn|
          # Fixme: This is a workaround to guarantee we're in a fresh connection
          conn.reset! if conn.transaction_open?
          conn.raw_connection.exec("CALL refresh_continuous_aggregate('#{table_name}', NULL, NULL)")
        end
      end
    end
  end

  MaterializedViews = [
    PerMinute = cagg['per_minute'],
    PerHour   = cagg['per_hour'],
    PerDay    = cagg['per_day'],
    PerMonth  = cagg['per_month'],
    GemsPerMinute = cagg['gems_per_minute'],
    GemsPerHour   = cagg['gems_per_hour'],
    GemsPerDay    = cagg['gems_per_day'],
    GemsPerMonth  = cagg['gems_per_month'],
    VersionsPerMinute = cagg['versions_per_minute'],
    VersionsPerHour   = cagg['versions_per_hour'],
    VersionsPerDay    = cagg['versions_per_day'],
    VersionsPerMonth  = cagg['versions_per_month']
  ]
end
