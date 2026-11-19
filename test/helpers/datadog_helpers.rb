# frozen_string_literal: true

module DatadogHelpers
  # Runs the block inside a real Datadog trace with test-mode tracing enabled so
  # that Datadog::Kit::AppSec::Events.track writes its tags onto a span we can
  # assert against. This exercises the real AppSec SDK rather than a stub.
  #
  # Returns the active span the SDK wrote to (which is not the span yielded by
  # Datadog::Tracing.trace).
  def with_appsec_trace(&)
    previous_tracing_enabled = Datadog.configuration.tracing.enabled
    previous_test_mode_enabled = Datadog.configuration.tracing.test_mode.enabled

    Datadog.configure do |c|
      c.tracing.enabled = true
      c.tracing.test_mode.enabled = true
    end

    span = nil
    Datadog::Tracing.trace("test.appsec") do
      @appsec_event_calls = count_appsec_events { @login_event_calls = count_login_event_calls(&) }
      span = Datadog::Tracing.active_span
    end
    span
  ensure
    Datadog.configure do |c|
      c.tracing.enabled = previous_tracing_enabled
      c.tracing.test_mode.enabled = previous_test_mode_enabled
    end
  end

  def count_login_event_calls
    events = Datadog::Kit::AppSec::Events::V2
    calls = Hash.new(0)
    originals = %i[track_user_login_success track_user_login_failure].index_with { |name| events.method(name) }
    originals.each do |name, original|
      events.define_singleton_method(name) do |*args|
        calls[name] += 1
        original.call(*args)
      end
    end
    yield
    calls
  ensure
    originals.each { |name, original| events.define_singleton_method(name, original) }
  end

  def count_appsec_events
    events = Datadog::Kit::AppSec::Events
    original = events.method(:track)
    counts = Hash.new(0)
    events.define_singleton_method(:track) do |event, *args, **kwargs|
      counts[event] += 1
      original.call(event, *args, **kwargs)
    end
    yield
    counts
  ensure
    events.define_singleton_method(:track, original)
  end

  def appsec_event_family_tags(span, prefix)
    span.tags.select { |key, _| key.start_with?("appsec.events.#{prefix}") }
  end

  def appsec_event_tags(span, event)
    prefix = "appsec.events.#{event}."
    span.tags.filter_map { |key, value| [key.delete_prefix(prefix), value] if key.start_with?(prefix) }.to_h
  end

  def assert_login_failure_tracked(span, login:, reason:, user: nil)
    assert_equal "true", span.get_tag("appsec.events.users.login.failure.track")
    assert_equal Digest::SHA256.hexdigest(login), span.get_tag("appsec.events.users.login.failure.usr.login")
    assert_equal user.present?.to_s, span.get_tag("appsec.events.users.login.failure.usr.exists")
    assert_equal reason, span.get_tag("appsec.events.users.login.failure.failure_reason")
    if user
      assert_equal user.id.to_s, span.get_tag("appsec.events.users.login.failure.usr.id")
    else
      assert_nil span.get_tag("appsec.events.users.login.failure.usr.id")
    end

    assert_nil span.get_tag("appsec.events.users.login.success.track")
    assert_nil span.get_tag("usr.id")
    assert_equal({ track_user_login_failure: 1 }, @login_event_calls)
    refute_tags_include(span, login)
  end

  def refute_tags_include(span, *secrets)
    span.tags.each_value do |value|
      secrets.each { |secret| refute_includes value.to_s, secret }
    end
  end

  def refute_login_tracked(span)
    assert_empty span.tags.keys.grep(/users\.login/)
    assert_empty @login_event_calls
  end
end
