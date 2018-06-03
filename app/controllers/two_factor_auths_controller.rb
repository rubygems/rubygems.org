class TwoFactorAuthsController < ApplicationController
  before_action :redirect_to_root, unless: :signed_in?
  before_action :require_no_auth, only: %i[new create]
  before_action :require_auth_set, only: :destroy

  def new
    seed, @recovery = User.generate_mfa
    session[:mfa_seed] = seed
    session[:mfa_recovery] = @recovery
    @text = ROTP::TOTP.new(seed, issuer: 'RubyGems.org').provisioning_uri(current_user.email)
    @qrcode_svg = RQRCode::QRCode.new(@text, level: :l).as_svg
  end

  def create
    seed = session[:mfa_seed]
    recovery = session[:mfa_recovery]
    session[:mfa_seed] = session[:mfa_recovery] = nil
    totp = ROTP::TOTP.new(seed, issuer: 'RubyGems.org')
    if totp.verify(params[:otp])
      current_user.enable_mfa!(seed, recovery, :auth_only)
      flash[:success] = t('.enable_success')
    else
      flash[:error] = t('.otp_auth_failed')
    end
    redirect_to edit_profile_url
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
