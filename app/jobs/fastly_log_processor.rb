require "zlib"

class FastlyLogProcessor
  class LogFileNotFoundError < ::StandardError; end

  extend StatsD::Instrument

  attr_accessor :bucket, :key

  def initialize(bucket, key)
    @bucket = bucket
    @key = key
  end

  def perform
    StatsD.increment("fastly_log_processor.started")

    log_ticket = LogTicket.pop(key: key, directory: bucket)
    if log_ticket.nil?
      StatsD.increment("fastly_log_processor.extra")
      Rails.logger.debug { "No log ticket for key=#{key} directory=#{bucket}, ignoring" }
      return
    end

    counts_by_bucket = download_counts(log_ticket)
    counts = counts_by_bucket.transform_values { |h| h.sum { |_, v| v } }
    StatsD.gauge("fastly_log_processor.processed_versions_count", counts.count)
    Rails.logger.info "Processed Fastly log counts: #{counts.inspect}"

    # insert into timescale first since it is idempotent and GemDownload is not
    record_downloads(counts_by_bucket, log_ticket.id)

    processed_count = counts.sum { |_, v| v }
    GemDownload.for_all_gems.with_lock do
      GemDownload.bulk_update(counts)
      log_ticket.update(status: "processed", processed_count: processed_count)
    end
    StatsD.gauge("fastly_log_processor.processed_count", processed_count)
  rescue StandardError
    log_ticket&.update(status: "failed")
    raise
  end
  statsd_count_success :perform, "fastly_log_processor.perform"
  statsd_measure :perform, "fastly_log_processor.job_performance"

  PATH_PATTERN = %r{/gems/(?<path>.+)\.gem}
  private_constant :PATH_PATTERN

  # Takes an enumerator of log lines and returns a hash of download counts
  # E.g.
  #   {
  #     'rails-4.0.0' => 25,
  #     'rails-4.2.0' => 50
  #   }
  def download_counts(log_ticket)
    file = log_ticket.body
    raise LogFileNotFoundError if file.nil?

    ok_status           = Rack::Utils::SYMBOL_TO_STATUS_CODE[:ok]
    not_modified_status = Rack::Utils::SYMBOL_TO_STATUS_CODE[:not_modified]

    file.each_line.with_object(Hash.new { |h, k| h[k] = Hash.new(0) }) do |log_line, accum|
      parts = log_line.split
      path, response_code = parts[10, 2]
      case response_code.to_i
      # Only count successful downloads
      # NB: we consider a 304 response a download attempt
      when ok_status, not_modified_status
        if (match = PATH_PATTERN.match(path))
          timestamp = parts[0].sub!(/\A<\d+>/, "")
          accum[match[:path]][truncated_timestamp(timestamp)] += 1
        end
      end
    end
  end

  def truncated_timestamp(timestamp)
    return unless timestamp
    time = Time.iso8601(timestamp)
    time.change(min: time.min / 15 * 15)
  rescue Date::Error
    nil
  end

  VERSION_PLUCK_ID_LIMIT = 1000
  DOWNLOAD_UPSERT_LIMIT = 1000

  def record_downloads(counts_by_bucket, log_ticket_id)
    ids_by_full_name = counts_by_bucket.each_key.each_slice(VERSION_PLUCK_ID_LIMIT).with_object({}) do |full_names, hash|
      Version.where(full_name: full_names).pluck(:full_name, :id, :rubygem_id).each { |full_name, *ids| hash[full_name] = ids }
    end

    counts_by_bucket
      .lazy
      .flat_map do |path, buckets|
        versions = ids_by_full_name[path]
        if versions.nil?
          Rails.logger.debug { "No version found for path=#{path}" }
          next
        end

        version_id, rubygem_id = versions

        buckets.map do |occurred_at, downloads|
          { version_id:, rubygem_id:, occurred_at:, downloads:, log_ticket_id: }
        end
      end # rubocop:disable Style/MultilineBlockChain
      .compact
      .each_slice(DOWNLOAD_UPSERT_LIMIT) do |inserts|
        # next unless Download.hypertable?
        Download.upsert_all(
          inserts,
          update_only: %i[downloads],
          unique_by: %i[rubygem_id version_id occurred_at log_ticket_id]
        )
      end
  end
end
