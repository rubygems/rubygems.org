require "zlib"

# Process log files downloaded from Fastly and insert row by row into the database.
# It works in a similar way to FastlyLogProcessor, but it's optimized for a different
# use case: it processes log files downloaded from Fastly and inserts the raw data into
# the database in batches.
# The counters and other metrics are calculated in a separate job directly in
# the database through the continuous aggregates.
# Check Download::PerMinute, Download::PerHour and other classes as an example.
class FastlyLogDownloadsProcessor
  class LogFileNotFoundError < ::StandardError; end

  extend StatsD::Instrument

  BATCH_SIZE = 5000

  attr_accessor :bucket, :key

  def initialize(bucket, key)
    @bucket = bucket
    @key = key
    @processed_count = 0
    @batch = []
  end

  def perform
    StatsD.increment("fastly_log_downloads_processor.started")
    raise LogFileNotFoundError if body.nil?

    downloads = parse_success_downloads
    downloads.each_slice(BATCH_SIZE) do |batch|
      Download.insert_all batch
    end

    StatsD.gauge("fastly_log_downloads_processor.processed_count", downloads.size)
  end

  def body
    @body ||= LogTicket.find_by(key: key, directory: bucket)&.body
  end

  def parse_success_downloads
    body.each_line.map do |log_line|
      fragments = log_line.split
      path, response_code = fragments[10, 2]
      case response_code.to_i
        # Only count successful downloads
        # NB: we consider a 304 response a download attempt
      when 200, 304
        m = path.match(PATH_PATTERN)
        gem_name = m[:gem_name] || path
        gem_version = m[:gem_version]
        ts = Time.parse fragments[4..9].join(' ')
        env = parse_env fragments[12..-1]
        payload = {env:}

        {ts:, gem_name:, gem_version:, payload:}
      end
    end.compact
  end


  # Parse the env into a hash of key value pairs
  # example env = "bundler/2.5.9 rubygems/3.3.25 ruby/3.1.0"
  # output = {bundler: "2.5.9", rubygems: "3.3.25", ruby: "3.1.0"}
  # case it says single word like jruby it appends true as the value
  # example env = "jruby"
  # output = {jruby: "true"}
  # also removes some unwanted characters
  def parse_env(output)
    env = output.join(' ').gsub(/command.*|\(.*\)|Ruby, /,'').strip
    env = nil if env == "(null)"
    env = env.split(' ').map do |info|
      pair = info.split(/\/|-/,2)
      pair << "true" if pair.size == 1
      pair
    end.to_h
  end

  statsd_count_success :perform, "fastly_log_downloads_processor.perform"
  statsd_measure :perform, "fastly_log_downloads_processor.job_performance"

  PATH_PATTERN = /\/gems\/(?<gem_name>.*)-(?<gem_version>\d+.*)\.gem/
  private_constant :PATH_PATTERN
end
