# frozen_string_literal: true

class SyncDisposableEmailDomainsJob < ApplicationJob
  queue_as "stats"

  UPSTREAM_BASE = "https://raw.githubusercontent.com/disposable-email-domains/disposable-email-domains/main"
  BLOCKLIST_URL = "#{UPSTREAM_BASE}/disposable_email_blocklist.conf".freeze
  ALLOWLIST_URL = "#{UPSTREAM_BASE}/allowlist.conf".freeze

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
    blocklist = fetch_lines(BLOCKLIST_URL)
    allowlist = fetch_lines(ALLOWLIST_URL).to_set
    blocklist.reject { |d| allowlist.include?(d) }.uniq
  end

  def fetch_lines(url)
    response = Net::HTTP.get_response(URI(url))
    raise "Unexpected response from #{url}: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    response.body.each_line.map { |l| l.split("#", 2).first.to_s.strip.downcase }.reject(&:empty?)
  end

  def upsert_domains(domains)
    BlockedEmailDomain.transaction do
      domains.each_slice(1000) do |slice|
        BlockedEmailDomain.upsert_all(
          slice.map { |d| { domain: d, source: BlockedEmailDomain.sources[:upstream] } },
          unique_by: :domain
        )
      end
      BlockedEmailDomain.upstream.where.not(domain: domains).delete_all
    end
  end
end
