class TwoFactorAuthsController < ApplicationController
  before_action :check_feature_flag
  before_action :redirect_to_root, unless: :signed_in?
  before_action :require_mfa_disabled, only: %i[new create]
  before_action :require_mfa_enabled, only: :destroy
  helper_method :issuer

  def new
    @seed = ROTP::Base32.random_base32
    session[:mfa_seed] = @seed
    text = ROTP::TOTP.new(@seed, issuer: issuer).provisioning_uri(current_user.email)
    @qrcode_svg = RQRCode::QRCode.new(text, level: :l).as_svg
  end

  def create
    seed = session[:mfa_seed]
    session.delete(:mfa_seed)
    totp = ROTP::TOTP.new(seed, issuer: issuer)
    if totp.verify(params[:otp])
      current_user.enable_mfa!(seed, :auth_only)
      flash[:success] = t('.enable_success')
      render :recovery
    else
      flash[:error] = t('.otp_auth_failed')
      redirect_to edit_profile_url
    end
  end

  def destroy
    if current_user.otp_verified?(params[:otp])
      flash[:success] = t('.disable_success')
      current_user.disable_mfa!
    else
      flash[:error] = t('two_factor_auths.create.otp_auth_failed')
    end
    redirect_to edit_profile_url
  end

  private

  def issuer
    request.host || 'rubygems.org'
  end

  def require_mfa_disabled
    return unless current_user.mfa_enabled?
    flash[:error] = t('two_factor_auths.authed_no_access')
    redirect_to edit_profile_path
  end

  def require_mfa_enabled
    return if current_user.mfa_enabled?
    flash[:error] = t('two_factor_auths.no_auth_no_access')
    redirect_to edit_profile_path
  end

  def check_feature_flag
    redirect_to edit_profile_path unless mfa_enabled?
  end
end
