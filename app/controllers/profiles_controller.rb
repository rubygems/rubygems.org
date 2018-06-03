class ProfilesController < ApplicationController
  before_action :redirect_to_root, unless: :signed_in?, except: :show
  before_action :verify_password, only: %i[update destroy]

  def edit
    @user = current_user
  end

  def show
    @user           = User.find_by_slug!(params[:id])
    rubygems        = @user.rubygems_downloaded
    @rubygems       = rubygems.slice!(0, 10)
    @extra_rubygems = rubygems
  end

  def update
    @user = current_user.clone
    if @user.update_attributes(params_user)
      if @user.unconfirmed_email
        Mailer.delay.email_reset(current_user)
        flash[:notice] = t('.confirmation_mail_sent')
      else
        flash[:notice] = t('.updated')
      end
      redirect_to edit_profile_path
    else
      current_user.reload
      render :edit
    end
  end

  def delete
    @only_owner_gems = current_user.only_owner_gems
    @multi_owner_gems = current_user.rubygems_downloaded - @only_owner_gems
  end

  def destroy
    Delayed::Job.enqueue DeleteUser.new(current_user), priority: PRIORITIES[:profile_deletion]
    sign_out
    redirect_to root_path, notice: t('.request_queued')
  end

  def mfa_setting
    seed, @recovery = User.generate_mfa
    session[:mfa_seed] = seed
    session[:mfa_recovery] = @recovery
    @text = ROTP::TOTP.new(seed, issuer: 'RubyGems.org').provisioning_uri(current_user.email)
    @qrcode_svg = RQRCode::QRCode.new(@text, level: :l).as_svg
  end

  def mfa_enable
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

  def mfa_disable
    if current_user.otp_verified?(params[:otp])
      flash[:success] = t('.disable_success')
      current_user.disable_mfa!
    else
      flash[:error] = t('profiles.mfa_enable.otp_auth_failed')
    end
    redirect_to edit_profile_url
  end

  private

  def params_user
    params.require(:user).permit(*User::PERMITTED_ATTRS)
  end

  def verify_password
    return if current_user.authenticated?(params[:user].delete(:password))
    flash[:notice] = t('profiles.request_denied')
    redirect_to edit_profile_path
  end
end
