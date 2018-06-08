class TwoFactorAuthsController < ApplicationController
  before_action :redirect_to_root, unless: :signed_in?
  before_action :require_no_auth, only: %i[new create]
  before_action :require_auth_set, only: :destroy
  helper_method :issuer

  def new
    @seed = ROTP::Base32.random_base32
    session[:mfa_seed] = @seed
    text = ROTP::TOTP.new(@seed, issuer: issuer).provisioning_uri(current_user.email)
    @qrcode_svg = RQRCode::QRCode.new(text, level: :l).as_svg
  end

  def create
    seed = session[:mfa_seed]
    session[:mfa_seed] = nil
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
      flash[:error] = t('profiles.mfa_enable.otp_auth_failed')
    end
    redirect_to edit_profile_url
  end

  private

  def issuer
    request.host || 'rubygems.org'
  end

  def require_no_auth
    return if current_user.no_auth?
    flash[:error] = t('two_factor_auths.authed_no_access')
    redirect_to edit_profile_path
  end

  def require_auth_set
    return unless current_user.no_auth?
    flash[:error] = t('two_factor_auths.no_auth_no_access')
    redirect_to edit_profile_path
  end
end
