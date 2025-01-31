module SessionVerifiable
  extend ActiveSupport::Concern

  class_methods do
    def verify_session_before(**)
      before_action(:redirect_to_signin, **, unless: :signed_in?)
      before_action(:redirect_to_new_mfa, **, if: :mfa_required_not_yet_enabled?)
      before_action(:redirect_to_settings_strong_mfa_required, **, if: :mfa_required_weak_level_enabled?)
      before_action(:redirect_to_verify, **, unless: :verified_session_active?)
    end
  end

  private

  def verify_session_redirect_path
    redirect_uri = request.path_info
    redirect_uri += "?#{request.query_string}" if request.query_string.present?
    redirect_uri
  end

  included do
    private

    def redirect_to_verify
      session[:redirect_uri] = verify_session_redirect_path
      redirect_to verify_session_path
    end

    def session_verified
      session[:verified_user] = current_user.id
      session[:verification] = Gemcutter::PASSWORD_VERIFICATION_EXPIRY.from_now
    end

    def verified_session_active?
      session[:verification] &&
        session[:verification] > Time.current &&
        session.fetch(:verified_user, "") == current_user.id
    end
  end
end
