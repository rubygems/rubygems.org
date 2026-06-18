# frozen_string_literal: true

# Blocks users whose email domain has expired and become available for
# purchase. Each confirmed user's email domain is checked against the Fastly
# Domain Research API; a domain reported as available (and with no MX record)
# is no longer controlled by its original owner, so the account is blocked.
#
# Previously run as a production-only Kubernetes CronJob invoking
# `rake users:verify`; now scheduled via GoodJob cron (production only, see
# config/initializers/good_job.rb).
class VerifyUserEmailDomainsJob < ApplicationJob
  queue_as "stats"

  include GoodJob::ActiveJobExtensions::Concurrency

  # Only one run at a time: the previous K8s CronJob used concurrencyPolicy: Forbid.
  good_job_control_concurrency_with(
    enqueue_limit: 1,
    perform_limit: 1,
    key: name
  )

  FASTLY_DOMAIN_RESEARCH_API = "https://api.fastly.com/domain-management/v1/tools/status"
  AVAILABLE_STATUS = %w[inactive parked expiring deleting].freeze
  EMAIL_DOMAIN_BOUNDARIES = [".", "@"].freeze

  # Block at most this many accounts automatically; above this, defer to manual review.
  MAX_AUTO_BLOCK = 20

  OPEN_TIMEOUT = 10
  READ_TIMEOUT = 30

  # A single domain check hitting one of these skips that domain rather than
  # aborting the whole batch. A total outage (every check failing) still raises.
  TRANSIENT_ERRORS = (HTTP_ERRORS + [
    Faraday::ConnectionFailed,
    Faraday::TimeoutError,
    Faraday::SSLError,
    SocketError,
    SystemCallError,
    OpenSSL::SSL::SSLError
  ]).freeze

  def perform
    # A missing key would make every request 401 and silently block nobody;
    # fail loudly so the misconfiguration is reported and alertable.
    raise "FASTLY_API_KEY is not configured" if ENV["FASTLY_API_KEY"].blank?

    StatsD.measure("user_email_domains.verify.duration") do
      domains = find_unique_domains
      failures = 0

      available_domains = domains.filter_map do |email_domain|
        root_domain = registrable_domain(email_domain)
        next if root_domain.nil?

        logger.info "checking domain: #{email_domain} root_domain: #{root_domain}"
        root_domain if domain_available?(email_domain, root_domain)
      rescue *TRANSIENT_ERRORS, JSON::ParserError => e
        failures += 1
        StatsD.increment("user_email_domains.verify.error", tags: { exception: e.class.name })
        notify "error checking domain: #{email_domain} error: #{e.class}: #{e.message}"
        nil
      end.uniq

      # Distinct subdomains can collapse to the same root, so deduplicate before
      # a total-outage check that should surface as a job error, not a silent no-op.
      raise "all #{domains.size} domain checks failed" if domains.any? && failures == domains.size

      StatsD.gauge("user_email_domains.verify.available", available_domains.size)
      blocked, deferred = block_users(available_domains)
      report_event(available_domains.size, blocked, deferred)
    end
  end

  private

  def domain_available?(email_domain, root_domain)
    response = fastly.get { |req| req.params["domain"] = root_domain }

    unless response.success?
      notify "Fastly Domain Research API request for #{root_domain} failed with status: #{response.status} body: #{response.body}"
      return false
    end

    domain_status_available?(response.body, email_domain)
  end

  def domain_status_available?(body, email_domain)
    json_body = JSON.parse(body)

    if (errors = json_body["errors"])
      notify "Fastly Domain Research API error for domain: #{email_domain} errors: #{errors}"
      return false
    end

    domain = json_body["domain"]
    status = json_body["status"]

    status&.split&.each do |item|
      next unless AVAILABLE_STATUS.include?(item) && no_mx_record?(email_domain, status)

      notify "domain: #{domain} is available for purchase with status: #{item}"
      return true
    end
    false
  end

  def fastly
    @fastly ||= Faraday.new(
      FASTLY_DOMAIN_RESEARCH_API,
      headers: { "Fastly-Key" => ENV.fetch("FASTLY_API_KEY") },
      request: { open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT }
    )
  end

  def find_unique_domains
    # The domain part of each confirmed user's email (everything after the @).
    # substring(text, pattern) is PostgreSQL's POSIX-regex form, equivalent to
    # substring(text FROM pattern).
    domain = Arel::Nodes::NamedFunction.new(
      "substring",
      [User.arel_table[:email], Arel::Nodes.build_quoted("@(.*)$")]
    )
    User.where(email_confirmed: true).distinct.pluck(domain)
  end

  # The registrable ("root") domain for an email domain, e.g.
  # mail.corp.example.co.uk -> example.co.uk. Returns nil for anything
  # PublicSuffix can't parse (skip rather than guess).
  def registrable_domain(email_domain)
    PublicSuffix.domain(email_domain.downcase)
  rescue PublicSuffix::Error
    nil
  end

  def no_mx_record?(domain, status)
    mx_records = Resolv::DNS.new.getresources(domain, Resolv::DNS::Resource::IN::MX).map { |r| r.exchange.to_s }
    return true if mx_records.empty?

    notify "please review domain: #{domain} status: #{status} mx: #{mx_records}"
    false
  rescue Resolv::ResolvError => e
    logger.info "ResolvError (#{e})"
    notify "please review domain: #{domain} status: #{status} mx: <failed>"
    false
  end

  def block_users(domains)
    users = domains.flat_map do |domain|
      User.where("email ILIKE ?", "%#{domain}").select do |user|
        # email matches should be of the format subdomain.domain or @domain
        EMAIL_DOMAIN_BOUNDARIES.include? user.email.downcase.chomp(domain)[-1]
      end
    end.uniq(&:id)

    if users.length <= MAX_AUTO_BLOCK
      users.each do |user|
        msg = "blocked user: #{user.display_handle} email: #{user.email} updated_at: #{user.updated_at} " \
              "gems: #{user.rubygems.count} total_downloads: #{user.total_downloads_count}"
        user.block!
        StatsD.increment("user_email_domains.verify.blocked")
        notify msg
      end
      [users.length, 0]
    else
      StatsD.gauge("user_email_domains.verify.manual_review", users.length)
      msg = "more than #{MAX_AUTO_BLOCK} user accounts with expired domains. please verify and block manually.\n" \
            "available_domains: #{domains}\n"
      users.each do |user|
        msg += "user: #{user.display_handle} email: #{user.email} updated_at: #{user.updated_at} " \
               "gems: #{user.rubygems.count} total_downloads: #{user.total_downloads_count}\n"
      end
      notify msg
      [0, users.length]
    end
  end

  # Posts a Datadog event (event stream) summarising the run, so blocks are
  # visible/searchable in Datadog beyond the raw counter metrics.
  def report_event(domain_count, blocked, deferred)
    if deferred.positive?
      text = "#{deferred} account(s) across #{domain_count} expired domain(s) exceeded the auto-block limit " \
             "(#{MAX_AUTO_BLOCK}) and were deferred for manual review. No accounts were blocked."
      alert_type = :warning
    else
      text = "Blocked #{blocked} account(s) across #{domain_count} expired domain(s)."
      alert_type = blocked.positive? ? :warning : :info
    end

    StatsD.event(
      "Expired email domain account blocking",
      text,
      alert_type: alert_type,
      aggregation_key: "verify_user_email_domains",
      tags: ["job:verify_user_email_domains", "blocked:#{blocked}", "deferred:#{deferred}", "domains:#{domain_count}"]
    )
  end

  # Surfaces noteworthy domains/actions to the logs (and, historically, Slack).
  def notify(msg)
    logger.info msg
  end
end
