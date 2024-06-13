require "app_revision"

Datadog.configure do |c|
  # unified service tagging

  c.service = "rubygems.org"
  c.version = AppRevision.version
  c.env = Rails.env

  # Enabling datadog functionality

  enabled = !Rails.env.local? && ENV["DD_AGENT_HOST"].present? && !defined?(Rails::Console)
  c.runtime_metrics.enabled = enabled
  c.profiling.enabled = enabled
  c.tracing.enabled = enabled
  c.tracing.log_injection = enabled
  c.telemetry.enabled = enabled
  c.remote.enabled = enabled

  unless enabled
    c.tracing.log_injection = false
    c.tracing.test_mode.enabled = true # Set transport to no-op mode. Does not retain traces.
    c.diagnostics.startup_logs.enabled = false
  end

  c.tags = {
    "git.commit.sha" => AppRevision.version,
    "git.repository_url" => "https://github.com/rubygems/rubygems.org"
  }

  # Configuring the datadog library

  c.logger.instance = SemanticLogger[Datadog]

  # Configuring tracing

  c.tracing.report_hostname = true

  c.tracing.instrument :aws
  c.tracing.instrument :dalli
  c.tracing.instrument :faraday, split_by_domain: true, service_name: c.service
  c.tracing.instrument :http, split_by_domain: true, service_name: c.service
  c.tracing.instrument :opensearch, service_name: c.service
  c.tracing.instrument :pg
  c.tracing.instrument :rails, request_queuing: true
  c.tracing.instrument :shoryuken
end

Datadog::Tracing.before_flush(
  # Remove spans for the /internal/ping endpoint
  Datadog::Tracing::Pipeline::SpanFilter.new { |span| span.resource == "Internal::PingController#index" }
)
