# frozen_string_literal: true

# Mirrors the upstream disposable-email-domains/disposable-email-domains blocklist
# into the blocked_email_domains table. Runs daily via good_job cron.
#
# Manual entries (source: :manual) are never touched. Upstream entries are
# upserted; entries that disappear from the upstream blocklist are deleted.
#
# Several safeguards protect against a compromised or broken upstream:
#
#   * MIN_EXPECTED_DOMAINS / MAX_EXPECTED_DOMAINS bound the accepted list size
#     so an empty response (e.g., 200 OK with HTML error page, repo wipe) or a
#     pathologically large payload aborts the sync without touching the DB.
#   * PROTECTED_PROVIDERS aborts the sync if any common consumer mail provider
#     appears in the upstream list, preventing a malicious upstream PR from
#     locking everyone out.
#   * Domains failing BlockedEmailDomain::DOMAIN_FORMAT are dropped, so
#     malformed lines never bypass the model's invariants via upsert_all.
class SyncDisposableEmailDomainsJob < ApplicationJob
  queue_as "stats"

  include GoodJob::ActiveJobExtensions::Concurrency

  good_job_control_concurrency_with(
    enqueue_limit: 1,
    perform_limit: 1,
    key: name
  )

  # Network-level failures are transient and worth retrying. HTTP status errors
  # (3xx/4xx/5xx) are surfaced via our own `response.success?` check below and
  # are NOT retried — the upstream URL is stable, so any of those is a signal
  # to investigate rather than retry.
  TRANSIENT_ERRORS = (HTTP_ERRORS + [
    Faraday::ConnectionFailed,
    Faraday::TimeoutError,
    Faraday::SSLError,
    SocketError,
    SystemCallError,
    OpenSSL::SSL::SSLError
  ]).freeze
  retry_on(*TRANSIENT_ERRORS, wait: :polynomially_longer, attempts: 3)

  BLOCKLIST_URL = "https://raw.githubusercontent.com/disposable-email-domains/disposable-email-domains/main/disposable_email_blocklist.conf"

  MIN_EXPECTED_DOMAINS = 1_000
  MAX_EXPECTED_DOMAINS = 100_000

  # Common consumer providers that must never appear on our blocklist. If any
  # of these show up upstream, treat the sync as poisoned and refuse to apply.
  PROTECTED_PROVIDERS = %w[
    gmail.com googlemail.com
    outlook.com hotmail.com live.com msn.com
    yahoo.com yahoo.co.uk ymail.com
    icloud.com me.com mac.com
    proton.me protonmail.com pm.me
    aol.com
    fastmail.com
  ].freeze

  OPEN_TIMEOUT = 10
  READ_TIMEOUT = 30

  class PoisonedUpstreamError < StandardError; end

  def perform
    StatsD.measure("disposable_email_domains.sync.duration") do
      domains = fetch_domains
      upsert_domains(domains)

      StatsD.gauge("disposable_email_domains.count", BlockedEmailDomain.count)
      StatsD.gauge("disposable_email_domains.upstream.count", BlockedEmailDomain.upstream.count)
      StatsD.increment("disposable_email_domains.sync.success")
    end
  rescue StandardError => e
    StatsD.increment("disposable_email_domains.sync.error", tags: { exception: e.class.name })
    Rails.error.report(e, handled: false)
    raise
  end

  private

  def fetch_domains
    domains = fetch_lines(BLOCKLIST_URL)
      .grep(BlockedEmailDomain::DOMAIN_FORMAT)
      .uniq

    if domains.size < MIN_EXPECTED_DOMAINS
      raise PoisonedUpstreamError, "Suspiciously small blocklist: #{domains.size} domains (expected >= #{MIN_EXPECTED_DOMAINS})"
    end
    if domains.size > MAX_EXPECTED_DOMAINS
      raise PoisonedUpstreamError, "Suspiciously large blocklist: #{domains.size} domains (expected <= #{MAX_EXPECTED_DOMAINS})"
    end

    protected_hits = domains & PROTECTED_PROVIDERS
    raise PoisonedUpstreamError, "Blocklist contains protected providers: #{protected_hits.join(', ')}" unless protected_hits.empty?

    domains
  end

  def fetch_lines(url)
    connection = Faraday.new(url, request: { open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT })
    response = connection.get

    # Redirects are deliberately not followed (Faraday doesn't follow by
    # default). The upstream URL is stable, so any 3xx — or any 4xx/5xx — is a
    # signal that something unexpected happened (host swap, takeover, GitHub
    # policy change). Fail loud and let ops investigate.
    raise "Unexpected response from #{url}: #{response.status}" unless response.success?

    response.body.each_line.map { |l| l.strip.downcase }.reject(&:empty?)
  end

  def upsert_domains(domains)
    synced_at = Time.current
    domains.each_slice(1000) do |slice|
      BlockedEmailDomain.upsert_all(
        slice.map do |d|
          { domain: d, source: BlockedEmailDomain.sources[:upstream],
            created_at: synced_at, updated_at: synced_at }
        end,
        unique_by: :domain,
        # Refresh updated_at only — do NOT reset source on rows an admin has
        # promoted to :manual, and do not bump created_at on existing rows.
        # record_timestamps: false stops Rails from auto-adding updated_at to
        # the SET clause (which would conflict with our explicit update_only).
        record_timestamps: false,
        update_only: [:updated_at]
      )
    end
    BlockedEmailDomain.upstream.where(updated_at: ...synced_at).delete_all
  end
end
