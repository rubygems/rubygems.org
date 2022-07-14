module ApplicationMultifactorMethods
  extend ActiveSupport::Concern

  included do
    def mfa_required_cookie?
      cookies[:mfa_required] == "true"
    end

    def redirect_to_new_mfa
      message = t("multifactor_auths.setup_required_html")
      redirect_to new_multifactor_auth_path, notice_html: message
    end

    def mfa_required_not_yet_enabled?
      return false if current_user.nil?
      current_user.mfa_required_not_yet_enabled? && mfa_required_cookie?
    end

    def redirect_to_settings_strong_mfa_required
      message = t("multifactor_auths.strong_mfa_level_required_html")
      redirect_to edit_settings_path, notice_html: message
    end

    def mfa_required_weak_level_enabled?
      return false if current_user.nil?
      current_user.mfa_required_weak_level_enabled? && mfa_required_cookie?
    end
  end
end
