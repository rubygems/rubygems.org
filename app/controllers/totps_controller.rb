class TotpsController < ApplicationController
  include MfaExpiryMethods
  include RequireMfa
  include WebauthnVerifiable

  before_action :redirect_to_signin, unless: :signed_in?
  before_action :require_totp_disabled, only: %i[new create]
  before_action :require_totp_enabled, only: :destroy
  before_action :seed_and_expire, only: :create
  before_action :disable_cache, only: %i[new]
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

  def destroy
    if current_user.ui_mfa_verified?(otp_param)
      flash[:success] = t(".success")
      current_user.disable_totp!
      redirect_to session.fetch("mfa_redirect_uri", edit_settings_path)
      session.delete("mfa_redirect_uri")
    else
      flash[:error] = t("totps.incorrect_otp")
      redirect_to edit_settings_path
    end
  end

  private

  def otp_param
    params.permit(:otp).fetch(:otp, "")
  end

  def issuer
    request.host || "rubygems.org"
  end

  def require_totp_disabled
    return if current_user.totp_disabled?
    flash[:error] = t("totps.require_totp_disabled", host: Gemcutter::HOST_DISPLAY)
    redirect_to edit_settings_path
  end

  def require_totp_enabled
    return if current_user.totp_enabled?

    flash[:error] = t("totps.require_totp_enabled")
    delete_mfa_session
    redirect_to edit_settings_path
  end

  def seed_and_expire
    @seed = session.delete(:totp_seed)
    @expire = Time.at(session.delete(:totp_seed_expire) || 0).utc
  end
end
