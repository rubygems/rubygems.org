# frozen_string_literal: true

module AppsecTracking
  private

  def identify_appsec_user(actor:)
    trace = Datadog::Tracing.active_trace
    return unless trace && actor

    Datadog::Kit::Identity.set_user(trace, id: actor.id.to_s, login: Digest::SHA256.hexdigest(actor.handle || actor.email))
  end

  def track_appsec_login_success(actor:)
    Datadog::Kit::AppSec::Events::V2.track_user_login_success(
      Digest::SHA256.hexdigest(actor.handle || actor.email), actor.id.to_s
    )
  end

  def track_appsec_login_failure(actor:, login: nil, **metadata)
    actor ||= begin
      User.find_by_email(login) || User.find_by(handle: login) if login.present?
    rescue Encoding::UndefinedConversionError
      nil
    end
    login = actor ? (actor.handle || actor.email) : login.to_s
    metadata[:"usr.id"] = actor.id.to_s if actor
    Datadog::Kit::AppSec::Events::V2.track_user_login_failure(Digest::SHA256.hexdigest(login), actor.present?, metadata)
  end

  def track_appsec_event(event, user: current_user, **metadata)
    metadata[:"usr.id"] = user.id.to_s if user
    Datadog::Kit::AppSec::Events.track(event, **metadata)
  end
end
