# frozen_string_literal: true

module DatadogHelpers
  # Runs the block inside a real Datadog trace with test-mode tracing enabled so
  # that Datadog::Kit::AppSec::Events.track writes its tags onto a span we can
  # assert against. This exercises the real AppSec SDK rather than a stub.
  #
  # Returns the active span the SDK wrote to (which is not the span yielded by
  # Datadog::Tracing.trace).
  def with_appsec_trace
    previous_tracing_enabled = Datadog.configuration.tracing.enabled
    previous_test_mode_enabled = Datadog.configuration.tracing.test_mode.enabled

    Datadog.configure do |c|
      c.tracing.enabled = true
      c.tracing.test_mode.enabled = true
    end

    span = nil
    Datadog::Tracing.trace("test.appsec") do
      yield
      span = Datadog::Tracing.active_span
    end
    span
  ensure
    Datadog.configure do |c|
      c.tracing.enabled = previous_tracing_enabled
      c.tracing.test_mode.enabled = previous_test_mode_enabled
    end
  end
end
