class MultifactorAuthsController < ApplicationController
  include MfaExpiryMethods

  before_action :redirect_to_signin, unless: :signed_in?
  before_action :require_mfa_disabled, only: %i[new create]
  before_action :require_mfa_enabled, only: :update
  before_action :seed_and_expire, only: :create
  helper_method :issuer

  def new
    @seed = ROTP::Base32.random_base32
    session[:mfa_seed] = @seed
    session[:mfa_seed_expire] = Gemcutter::MFA_KEY_EXPIRY.from_now.utc.to_i
    text = ROTP::TOTP.new(@seed, issuer: issuer).provisioning_uri(current_user.email)
    @qrcode_svg = RQRCode::QRCode.new(text, level: :l).as_svg(module_size: 6)
  end

  def create
    current_user.verify_and_enable_totp!(@seed, :ui_and_api, otp_param, @expire)
    if current_user.errors.any?
      flash[:error] = current_user.errors[:base].join
      redirect_to edit_settings_url
    else
      flash.now[:success] = t(".success")
      @continue_path = session.fetch("mfa_redirect_uri", edit_settings_path)
      session.delete("mfa_redirect_uri")
      render :recovery
    end
  end

  def update
    session[:level] = level_param
    @user = current_user

    setup_mfa_authentication
    setup_webauthn_authentication

    create_new_mfa_expiry

    render template: "multifactor_auths/mfa_prompt"
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

  def require_mfa_disabled
    return unless current_user.mfa_enabled?
    flash[:error] = t("multifactor_auths.require_mfa_disabled")
    redirect_to edit_settings_path
  end

  def require_mfa_enabled
    return if current_user.mfa_enabled?
    flash[:error] = t("multifactor_auths.require_mfa_enabled")
    redirect_to edit_settings_path
  end

  def seed_and_expire
    @seed = session[:mfa_seed]
    @expire = Time.at(session[:mfa_seed_expire] || 0).utc
    %i[mfa_seed mfa_seed_expire].each do |key|
      session.delete(key)
    end
  end

  def setup_mfa_authentication
    return if current_user.totp_disabled?
    @form_mfa_url = nil # TODO
  end

  def setup_webauthn_authentication
    return if current_user.webauthn_disabled?

    @webauthn_verification_url = nil # TODO

    @webauthn_options = current_user.webauthn_options_for_get

    session[:webauthn_authentication] = {
      "challenge" => @webauthn_options.challenge
    }
  end

  # rubocop:disable Rails/ActionControllerFlashBeforeRender
  def handle_new_level_param
    case level_param
    when "disabled"
      flash[:success] = t("multifactor_auths.destroy.success")
      current_user.disable_totp!
    when "ui_only"
      flash[:error] = t("multifactor_auths.ui_only_warning")
    else
      flash[:error] = t(".success")
      current_user.update!(mfa_level: level_param)
    end
  end
  # rubocop:enable Rails/ActionControllerFlashBeforeRender
end
