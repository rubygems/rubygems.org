module ApplicationMultifactorMethods
  extend ActiveSupport::Concern

  included do
    def redirect_to_new_mfa
      message = t("multifactor_auths.setup_required_html")
      session["mfa_redirect_uri"] = request.path_info
      redirect_to new_multifactor_auth_path, notice_html: message
    end

    def mfa_required_not_yet_enabled?
      return false if current_user.nil?
      current_user.mfa_required_not_yet_enabled?
    end

    def redirect_to_settings_strong_mfa_required
      message = t("multifactor_auths.strong_mfa_level_required_html")
      session["mfa_redirect_uri"] = request.path_info
      redirect_to edit_settings_path, notice_html: message
    end

    def mfa_required_weak_level_enabled?
      return false if current_user.nil?
      current_user.mfa_required_weak_level_enabled?
    end
  end
end
