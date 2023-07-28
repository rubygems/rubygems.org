class MultifactorAuthsController < ApplicationController
  include MfaExpiryMethods
  include WebauthnVerifiable

  before_action :redirect_to_signin, unless: :signed_in?
  before_action :require_totp_disabled, only: %i[new create]
  before_action :require_mfa_enabled, only: %i[update otp_update]
  before_action :require_totp_enabled, only: :destroy
  before_action :seed_and_expire, only: :create
  before_action :verify_session_expiration, only: %i[otp_update webauthn_update]
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
    session[:level] = level_param
    @user = current_user

    @otp_verification_url = otp_update_multifactor_auth_url(token: current_user.confirmation_token)
    setup_webauthn_authentication(form_url: webauthn_update_multifactor_auth_url(token: current_user.confirmation_token))

    create_new_mfa_expiry

    render template: "multifactor_auths/mfa_prompt"
  end

  def otp_update
    if current_user.ui_mfa_verified?(params[:otp])
      update_level_and_redirect
    else
      redirect_to edit_settings_path, flash: { error: t("multifactor_auths.incorrect_otp") }
    end
  end

  def webauthn_update
    @user = current_user
    unless @user.webauthn_enabled?
      redirect_to edit_settings_path, flash: { error: t("multifactor_auths.require_webauthn_enabled") }
      return
    end

    if webauthn_credential_verified?
      update_level_and_redirect
    else
      redirect_to edit_settings_path, flash: { error: @webauthn_error }
    end
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
    flash[:error] = t("multifactor_auths.require_totp_disabled")
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

  def seed_and_expire
    @seed = session[:totp_seed]
    @expire = Time.at(session[:totp_seed_expire] || 0).utc
    %i[totp_seed totp_seed_expire].each do |key|
      session.delete(key)
    end
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

  def verify_session_expiration
    return if session_active?

    delete_mfa_level_update_session_variables
    redirect_to edit_settings_path, flash: { error: t("multifactor_auths.session_expired") }
  end

  def delete_mfa_level_update_session_variables
    session.delete(:level)
    session.delete(:webauthn_authentication)
    delete_mfa_expiry_session
  end
end
