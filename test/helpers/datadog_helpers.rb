# frozen_string_literal: true

module DatadogHelpers
  # Pass a callable user when the action creates the account being asserted.
  def assert_appsec_event(event, user: nil, login: nil, metadata: {}, span: nil, &block)
    span ||= with_appsec_trace(&block)
    user = user.call if user.respond_to?(:call)
    prefix = "appsec.events.#{event}"

    assert_equal "true", span.get_tag("#{prefix}.track")

    if event.start_with?("users.")
      assert_appsec_login_tags(span, event, user, login)
    elsif user
      assert_equal user.id.to_s, span.get_tag("#{prefix}.usr.id")
    end

    metadata.each { |key, value| assert_appsec_tag(span, "#{prefix}.#{key}", value) }
    span
  end

  def assert_appsec_login_tags(span, event, user, login)
    prefix = "appsec.events.#{event}"
    if event == "users.login.failure"
      assert_equal user.present?.to_s, span.get_tag("#{prefix}.usr.exists")
      assert_appsec_tag(span, "#{prefix}.usr.id", user&.id)
    else
      assert_equal user.id.to_s, span.get_tag("usr.id")
    end

    login ||= user && (user.handle || user.email)
    assert_equal Digest::SHA256.hexdigest(login), span.get_tag("#{prefix}.usr.login") if login
  end

  def assert_appsec_tag(span, key, value)
    actual = span.get_tag(key)
    value.nil? ? assert_nil(actual) : assert_equal(value.to_s, actual)
  end

  def assert_appsec_user(user, &block)
    span = with_appsec_trace(&block)

    assert_equal user.id.to_s, span.get_tag("usr.id")
    assert_equal Digest::SHA256.hexdigest(user.handle || user.email), span.get_tag("usr.login")
  end

  def refute_appsec_event(event, span: nil, &block)
    span ||= with_appsec_trace(&block)

    assert_nil span.get_tag("appsec.events.#{event}.track")
  end

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
      span = Datadog::Tracing.active_span
      yield
    end
    span
  ensure
    Datadog.configure do |c|
      c.tracing.enabled = previous_tracing_enabled
      c.tracing.test_mode.enabled = previous_test_mode_enabled
    end
  end
end
