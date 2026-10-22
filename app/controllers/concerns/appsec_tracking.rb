# frozen_string_literal: true

module AppsecTracking
  private

  def identify_appsec_user(user)
    trace = Datadog::Tracing.active_trace
    return unless trace && user

    Datadog::Kit::Identity.set_user(trace, id: user.id.to_s, login: Digest::SHA256.hexdigest(user.handle || user.email))
  end

  def track_appsec_login_success(user)
    Datadog::Kit::AppSec::Events::V2.track_user_login_success(
      Digest::SHA256.hexdigest(user.handle || user.email), user.id.to_s
    )
  end

  def track_appsec_login_failure(user, login: nil, **metadata)
    user ||= begin
      User.find_by_email(login) || User.find_by(handle: login) if login.present?
    rescue Encoding::UndefinedConversionError
      nil
    end
    login = user ? (user.handle || user.email) : login.to_s
    metadata[:"usr.id"] = user.id.to_s if user
    Datadog::Kit::AppSec::Events::V2.track_user_login_failure(Digest::SHA256.hexdigest(login), user.present?, metadata)
  end

  def track_appsec_event(event, user: current_user, **metadata)
    metadata[:"usr.id"] = user.id.to_s if user
    Datadog::Kit::AppSec::Events.track(event, **metadata)
  end
end
