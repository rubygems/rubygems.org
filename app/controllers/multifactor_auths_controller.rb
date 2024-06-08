class MultifactorAuthsController < ApplicationController
  include MfaExpiryMethods
  include RequireMfa
  include WebauthnVerifiable

  before_action :redirect_to_signin, unless: :signed_in?
  before_action :require_totp_disabled, only: %i[new create]
  before_action :require_mfa_enabled, only: %i[update otp_update]
  before_action :require_totp_enabled, only: :destroy
  before_action :seed_and_expire, only: :create
  before_action :find_mfa_user, only: %i[update otp_update webauthn_update]
  before_action :validate_otp, only: %i[otp_update]
  before_action :require_webauthn_enabled, only: %i[webauthn_update]
  before_action :validate_webauthn, only: %i[webauthn_update]
  before_action :disable_cache, only: %i[new recovery]
  after_action :delete_mfa_level_update_session_variables, only: %i[otp_update webauthn_update]
  helper_method :issuer

  def new
    @seed = ROTP::Base32.random_base32
    session[:totp_seed] = @seed
    session[:totp_seed_expire] = Gemcutter::MFA_KEY_EXPIRY.from_now.utc.to_i
    text = ROTP::TOTP.new(@seed, issuer: issuer).provisioning_uri(current_user.email)
    @qrcode_svg = RQRCode::QRCode.new(text, level: :l).as_svg(module_size: 6)
  end

  def create
    current_user.verify_and_enable_totp!(@seed, :ui_and_api, otp_param, @expire)
    if current_user.errors.any?
      flash[:error] = current_user.errors[:base].join
      redirect_to edit_settings_url
    else
      flash[:success] = t(".success")
      @continue_path = session.fetch("mfa_redirect_uri", edit_settings_path)

      if current_user.mfa_device_count_one?
        session[:show_recovery_codes] = current_user.new_mfa_recovery_codes
        redirect_to recovery_multifactor_auth_path
      else
        redirect_to @continue_path
        session.delete("mfa_redirect_uri")
      end
    end
  end

  def update
    initialize_mfa(@user)
    session[:level] = level_param
    prompt_mfa
  end

  def otp_update
    update_level_and_redirect
  end

  def webauthn_update
    update_level_and_redirect
  end

  def destroy
    if current_user.ui_mfa_verified?(otp_param)
      flash[:success] = t(".success")
      current_user.disable_totp!
      redirect_to session.fetch("mfa_redirect_uri", edit_settings_path)
      session.delete("mfa_redirect_uri")
    else
      flash[:error] = t("multifactor_auths.incorrect_otp")
      redirect_to edit_settings_path
    end
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

  def otp_param
    params.permit(:otp).fetch(:otp, "")
  end

  def level_param
    params.permit(:level).fetch(:level, "")
  end

  def issuer
    request.host || "rubygems.org"
  end

  def require_totp_disabled
    return if current_user.totp_disabled?
    flash[:error] = t("multifactor_auths.require_totp_disabled", host: Gemcutter::HOST_DISPLAY)
    redirect_to edit_settings_path
  end

  def require_mfa_enabled
    return if current_user.mfa_enabled?
    flash[:error] = t("multifactor_auths.require_mfa_enabled")
    redirect_to edit_settings_path
  end

  def require_totp_enabled
    return if current_user.totp_enabled?

    flash[:error] = t("multifactor_auths.require_totp_enabled")
    delete_mfa_level_update_session_variables
    redirect_to edit_settings_path
  end

  def require_webauthn_enabled
    return if current_user.webauthn_enabled?

    flash[:error] = t("multifactor_auths.require_webauthn_enabled")
    delete_mfa_level_update_session_variables
    redirect_to edit_settings_path
  end

  def seed_and_expire
    @seed = session.delete(:totp_seed)
    @expire = Time.at(session.delete(:totp_seed_expire) || 0).utc
  end

  def update_level_and_redirect
    handle_new_level_param
    redirect_to session.fetch("mfa_redirect_uri", edit_settings_path)
    session.delete(:mfa_redirect_uri)
  end

  # rubocop:disable Rails/ActionControllerFlashBeforeRender
  def handle_new_level_param
    case session[:level]
    when "ui_and_api", "ui_and_gem_signin"
      flash[:success] = t("multifactor_auths.update.success")
      current_user.update!(mfa_level: session[:level])
    else
      flash[:error] = t("multifactor_auths.update.invalid_level")
    end
  end
  # rubocop:enable Rails/ActionControllerFlashBeforeRender

  def find_mfa_user
    @user = current_user
  end

  def delete_mfa_level_update_session_variables
    session.delete(:level)
    session.delete(:webauthn_authentication)
    delete_mfa_expiry_session
  end

  def mfa_failure(message)
    delete_mfa_level_update_session_variables
    redirect_to edit_settings_path, flash: { error: message }
  end

  def otp_verification_url
    otp_update_multifactor_auth_url(token: current_user.confirmation_token)
  end

  def webauthn_verification_url
    webauthn_update_multifactor_auth_url(token: current_user.confirmation_token)
  end
end
