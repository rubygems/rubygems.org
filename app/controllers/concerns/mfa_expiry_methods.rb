module MfaExpiryMethods
  extend ActiveSupport::Concern

  included do
    def create_new_mfa_expiry
      session[:mfa_expires_at] = 15.minutes.from_now.to_s
    end

    def delete_mfa_expiry_session
      session.delete(:mfa_expires_at)
    end

    def session_active?
      return false if session[:mfa_expires_at].nil?
      session[:mfa_expires_at] > Time.current
    end
  end
end
