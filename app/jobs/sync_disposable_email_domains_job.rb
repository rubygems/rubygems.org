# frozen_string_literal: true

# Mirrors the upstream disposable-email-domains blocklist into the
# blocked_email_domains table daily. Manual entries are never touched.
class SyncDisposableEmailDomainsJob < ApplicationJob
  queue_as "stats"

  include GoodJob::ActiveJobExtensions::Concurrency

  good_job_control_concurrency_with(
    enqueue_limit: 1,
    perform_limit: 1,
    key: name
  )

  TRANSIENT_ERRORS = (HTTP_ERRORS + [
    Faraday::ConnectionFailed,
    Faraday::TimeoutError,
    Faraday::SSLError,
    SocketError,
    SystemCallError,
    OpenSSL::SSL::SSLError
  ]).freeze
  retry_on(*TRANSIENT_ERRORS, wait: :polynomially_longer, attempts: 3)

  # attempts: 1 short-circuits ApplicationJob's broad retry_on StandardError so
  # these surface immediately instead of being silently retried for ~10 minutes.
  class PoisonedUpstreamError < StandardError; end
  class UpstreamHttpError < StandardError; end
  retry_on PoisonedUpstreamError, UpstreamHttpError, attempts: 1

  BLOCKLIST_URL = "https://raw.githubusercontent.com/disposable-email-domains/disposable-email-domains/main/disposable_email_blocklist.conf"

  MIN_EXPECTED_DOMAINS = 1_000
  MAX_EXPECTED_DOMAINS = 500_000
  MAX_DELTA_PERCENT = 50

  OPEN_TIMEOUT = 10
  READ_TIMEOUT = 30
  MAX_RESPONSE_BYTES = 50 * 1024 * 1024

  def perform
    StatsD.measure("disposable_email_domains.sync.duration") do
      domains = fetch_domains
      upsert_domains(domains)

      StatsD.gauge("disposable_email_domains.count", BlockedEmailDomain.count)
      StatsD.gauge("disposable_email_domains.upstream.count", BlockedEmailDomain.upstream.count)
      StatsD.increment("disposable_email_domains.sync.success")
    end
  rescue StandardError => e
    terminal = last_attempt?(e)
    StatsD.increment("disposable_email_domains.sync.error",
      tags: { exception: e.class.name, terminal: terminal.to_s })
    Rails.error.report(e, handled: !terminal)
    raise
  end

  private

  def last_attempt?(error)
    case error
    when PoisonedUpstreamError, UpstreamHttpError
      true
    when *TRANSIENT_ERRORS
      executions >= 3
    else
      executions >= 5
    end
  end

  def fetch_domains
    domains = fetch_lines(BLOCKLIST_URL)
      .grep(BlockedEmailDomain::DOMAIN_FORMAT)
      .select { |d| PublicSuffix.valid?(d) }
      .uniq

    if domains.size < MIN_EXPECTED_DOMAINS
      raise PoisonedUpstreamError, "Suspiciously small blocklist: #{domains.size} domains (expected >= #{MIN_EXPECTED_DOMAINS})"
    end
    if domains.size > MAX_EXPECTED_DOMAINS
      raise PoisonedUpstreamError, "Suspiciously large blocklist: #{domains.size} domains (expected <= #{MAX_EXPECTED_DOMAINS})"
    end

    protected_hits = domains & BlockedEmailDomain::PROTECTED_PROVIDERS
    raise PoisonedUpstreamError, "Blocklist contains protected providers: #{protected_hits.join(', ')}" unless protected_hits.empty?

    check_delta(domains.size)

    domains
  end

  def check_delta(new_size)
    current = BlockedEmailDomain.upstream.count
    StatsD.gauge("disposable_email_domains.upstream.previous_count", current)
    StatsD.gauge("disposable_email_domains.upstream.next_count", new_size)
    return if no_baseline?(current)

    delta_pct = ((new_size - current).abs.to_f / current * 100).round(1)
    StatsD.gauge("disposable_email_domains.upstream.delta_pct", delta_pct)
    return if delta_pct <= MAX_DELTA_PERCENT

    raise PoisonedUpstreamError,
      "Blocklist size changed by #{delta_pct}% (#{current} -> #{new_size}); expected <= #{MAX_DELTA_PERCENT}%"
  end

  def no_baseline?(current_size)
    current_size < MIN_EXPECTED_DOMAINS
  end

  def fetch_lines(url)
    connection = Faraday.new(url, request: { open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT })
    response = connection.get

    raise UpstreamHttpError, "Unexpected response from #{url}: #{response.status}" unless response.success?

    if response.body.bytesize > MAX_RESPONSE_BYTES
      raise PoisonedUpstreamError, "Response body too large: #{response.body.bytesize} bytes (max #{MAX_RESPONSE_BYTES})"
    end

    response.body.each_line.map { |l| l.strip.downcase }.reject(&:empty?)
  end

  def upsert_domains(domains)
    synced_at = Time.current
    BlockedEmailDomain.transaction do
      domains.each_slice(1000) do |slice|
        BlockedEmailDomain.upsert_all(
          slice.map do |d|
            { domain: d, source: BlockedEmailDomain.sources[:upstream],
              created_at: synced_at, updated_at: synced_at }
          end,
          unique_by: :domain,
          # Preserve :manual source on rows an admin has promoted; only refresh updated_at.
          record_timestamps: false,
          update_only: [:updated_at]
        )
      end
      BlockedEmailDomain.upstream.where(updated_at: ...synced_at).delete_all
    end
  end
end
