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
      return
    end

    counts = download_counts(log_ticket)
    StatsD.gauge("fastly_log_processor.processed_versions_count", counts.count)
    Delayed::Worker.logger.info "Processed Fastly log counts: #{counts.inspect}"

    processed_count = counts.sum { |_, v| v }
    ActiveRecord::Base.connection.transaction do
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

  # Takes an enumerator of log lines and returns a hash of download counts
  # E.g.
  #   {
  #     'rails-4.0.0' => 25,
  #     'rails-4.2.0' => 50
  #   }
  def download_counts(log_ticket)
    file = log_ticket.body
    raise LogFileNotFoundError if file.nil?
    enumerator = file.each_line

    enumerator.each_with_object(Hash.new(0)) do |log_line, accum|
      path, response_code = log_line.split[10, 2]
      # Only count successful downloads
      # NB: we consider a 304 response a download attempt
      ok_status           = Rack::Utils::SYMBOL_TO_STATUS_CODE[:ok]
      not_modified_status = Rack::Utils::SYMBOL_TO_STATUS_CODE[:not_modified]
      if [ok_status, not_modified_status].include?(response_code.to_i) && (match = path.match %r{/gems/(?<path>.+)\.gem})
        accum[match[:path]] += 1
      end

      accum
    end
  end
end
