# frozen_string_literal: true

class Advisory::Fetcher
  BATCH_SIZE = 500
  OPEN_TIMEOUT = 10
  READ_TIMEOUT = 60

  RETRY_EXCEPTIONS = [
    Faraday::ConnectionFailed,
    Faraday::TimeoutError,
    Faraday::ServerError,
    Faraday::TooManyRequestsError
  ].freeze

  UPDATE_COLUMNS = %i[
    aliases summary severity url published_at modified_at withdrawn_at ranges payload
  ].freeze

  class Error < StandardError; end

  class << self
    def advisory_class
      raise NotImplementedError, "#{name} must define .advisory_class"
    end

    delegate :enabled?, to: :advisory_class

    def sources
      Advisory::SOURCES.map { |klass| klass::Fetcher }
    end

    def sync_all
      Advisory.enabled_sources.each { |klass| klass::Fetcher.new.sync }
    end

    def sync(source, force: false)
      klass = source.is_a?(Class) ? source : source.constantize
      raise ArgumentError, "Unknown advisory source: #{source.inspect}" unless Advisory::SOURCES.include?(klass)

      klass::Fetcher.new.sync(force:)
    end
  end

  def sync(force: false)
    return unless force || self.class.enabled?

    import(fetch.flat_map { |document| map(document) })
  end

  def fetch
    raise NotImplementedError, "#{self.class}#fetch must be implemented"
  end

  def map(_document)
    raise NotImplementedError, "#{self.class}#map must be implemented"
  end

  def download(url)
    connection.get(url).body.to_s
  end

  def import(records)
    return 0 if records.empty?

    self.class.advisory_class.transaction do
      records.each_slice(BATCH_SIZE) do |slice|
        self.class.advisory_class.upsert_all(
          slice,
          unique_by: %i[type identifier rubygem_name],
          update_only: UPDATE_COLUMNS
        )
      end
    end

    records.size
  end

  private

  def connection
    @connection ||= Faraday.new(
      request: { open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT },
      headers: { "User-Agent" => "RubyGems.org Advisory Fetcher/#{AppRevision.version}" }
    ) do |f|
      f.request :retry, max: 2, interval: 0.05, backoff_factor: 2, methods: %i[get], exceptions: RETRY_EXCEPTIONS
      f.response :raise_error
    end
  end
end
