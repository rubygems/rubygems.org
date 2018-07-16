class MultifactorAuthsController < ApplicationController
  before_action :check_feature_flag
  before_action :redirect_to_root, unless: :signed_in?
  before_action :require_mfa_disabled, only: %i[new create]
  before_action :require_mfa_enabled, only: :destroy
  helper_method :issuer

  def new
    @seed = ROTP::Base32.random_base32
    session[:mfa_seed] = @seed
    session[:mfa_seed_expire] = (Time.now.utc + 30.minutes).to_i
    text = ROTP::TOTP.new(@seed, issuer: issuer).provisioning_uri(current_user.email)
    @qrcode_svg = RQRCode::QRCode.new(text, level: :l).as_svg
  end

  def create
    seed = session[:mfa_seed]
    expire = Time.at(session[:mfa_seed_expire] || 0).utc
    %i[mfa_seed mfa_seed_expire].each do |key|
      session.delete(key)
    end

    totp = ROTP::TOTP.new(seed, issuer: issuer)
    if Time.now.utc > expire
      flash[:error] = t('.qrcode_expired')
      redirect_to edit_profile_url
    elsif totp.verify(params[:otp])
      current_user.enable_mfa!(seed, :mfa_login_only)
      current_user.update!(last_otp_at: Time.current)
      flash[:success] = t('.success')
      render :recovery
    else
      flash[:error] = t('multifactor_auths.incorrect_otp')
      redirect_to edit_profile_url
    end
  end

  def destroy
    if current_user.otp_verified?(params[:otp])
      flash[:success] = t('.success')
      current_user.disable_mfa!
    else
      flash[:error] = t('multifactor_auths.incorrect_otp')
    end
    redirect_to edit_profile_url
  end

  private

  def issuer
    request.host || 'rubygems.org'
  end

  def require_mfa_disabled
    return unless current_user.mfa_enabled?
    flash[:error] = t('multifactor_auths.require_mfa_disabled')
    redirect_to edit_profile_path
  end

  def require_mfa_enabled
    return if current_user.mfa_enabled?
    flash[:error] = t('multifactor_auths.require_mfa_enabled')
    redirect_to edit_profile_path
  end

  def check_feature_flag
    redirect_to edit_profile_path unless mfa_enabled?
  end
end
