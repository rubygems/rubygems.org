class MultifactorAuthsController < ApplicationController
  include MfaExpiryMethods
  include RequireMfa
  include WebauthnVerifiable

  before_action :redirect_to_signin, unless: :signed_in?
  before_action :require_mfa_enabled, only: %i[update otp_update]
  before_action :find_mfa_user, only: %i[update otp_update webauthn_update]
  before_action :require_mfa, only: %i[update]
  before_action :validate_otp, only: %i[otp_update]
  before_action :require_webauthn_enabled, only: %i[webauthn_update]
  before_action :validate_webauthn, only: %i[webauthn_update]
  before_action :disable_cache, only: %i[recovery]
  after_action :delete_mfa_session, only: %i[otp_update webauthn_update]
  helper_method :issuer

  # not possible to arrive here because of require_mfa_enabled + require_mfa, but it must stay for rails to be happy.
  def update
  end

  def otp_update
    update_level_and_redirect
  end

  def webauthn_update
    update_level_and_redirect
  end

  def recovery
    @mfa_recovery_codes = session[:show_recovery_codes]
    if @mfa_recovery_codes.nil?
      redirect_to edit_settings_path
      flash[:error] = t(".already_generated")
      return
    end
    @continue_path = session.fetch("mfa_redirect_uri", edit_settings_path)
    session.delete("mfa_redirect_uri")
  ensure
    session.delete(:show_recovery_codes)
  end

  private

  def level_param
    params.permit(:level).require(:level)
  end

  def issuer
    request.host || "rubygems.org"
  end

  def require_mfa_enabled
    return if current_user.mfa_enabled?
    flash[:error] = t("multifactor_auths.require_mfa_enabled")
    redirect_to edit_settings_path
  end

  def require_webauthn_enabled
    return if current_user.webauthn_enabled?

    flash[:error] = t("multifactor_auths.require_webauthn_enabled")
    delete_mfa_session
    redirect_to edit_settings_path
  end

  def update_level_and_redirect
    case level_param
    when "ui_and_api", "ui_and_gem_signin"
      flash[:success] = t("multifactor_auths.update.success")
      current_user.update!(mfa_level: level_param)
    else
      flash[:error] = t("multifactor_auths.update.invalid_level") # rubocop:disable Rails/ActionControllerFlashBeforeRender
    end

    redirect_to session.fetch("mfa_redirect_uri", edit_settings_path)
    session.delete(:mfa_redirect_uri)
  end

  def find_mfa_user
    @user = current_user
  end

  def mfa_failure(message)
    delete_mfa_session
    redirect_to edit_settings_path, flash: { error: message }
  end
  alias login_failure mfa_failure

  def otp_verification_url
    otp_update_multifactor_auth_url(level: level_param)
  end

  def webauthn_verification_url
    webauthn_update_multifactor_auth_url(level: level_param)
  end
end
