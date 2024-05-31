module MfaExpiryMethods
  extend ActiveSupport::Concern

  included do
    def create_new_mfa_expiry
      session[:mfa_expires_at] = 15.minutes.from_now.to_s
    end

    def delete_mfa_expiry_session
      session.delete(:mfa_expires_at)
    end

    # Clear the session key when mfa has expired. This makes mfa_session_active? before_action guards simpler to write.
    def mfa_session_active?
      return false if session[:mfa_expires_at].nil?
      delete_mfa_expiry_session if Time.current > session[:mfa_expires_at]
      session[:mfa_expires_at].present?
    end
  end
end
